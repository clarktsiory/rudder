package com.normation.rudder.web.snippet

import com.normation.plugins.DefaultExtendableSnippet
import com.normation.rudder.domain.logger.ApplicationLogger
import com.normation.rudder.users.CurrentUser
import net.liftweb.http.DispatchSnippet
import net.liftweb.http.js.JE._
import net.liftweb.http.js.JsCmds._
import net.liftweb.util._
import net.liftweb.util.CanBind._
import scala.xml.NodeSeq

class CommonLayout extends DispatchSnippet with DefaultExtendableSnippet[CommonLayout] {

  def mainDispatch = Map(
    "display" -> init,
    "scripts" -> (_ => menuScript)
  )

  /*
   * This seems to be needed in top of common layout to correctly init
   * the session var just after login.
   */
  def init(xml: NodeSeq): NodeSeq = {
    CurrentUser.get match {
      case None    => ApplicationLogger.warn("Authz.init called but user not authenticated")
      case Some(_) => // expected
    }

    display(xml)
  }

  def display: CssSel = {
    "#toggleMenuButton" #> toggleMenuElement
  }

  val menuScript = WithNonce.scriptWithNonce(
    Script(
      OnLoad(
        JsRaw( // Toggle menu
          """$('body').toggleClass('sidebar-collapse');
            $('#toggleMenuButton').click(function() {
              $('body').toggleClass('sidebar-collapse');
            });
            """
        )
      )
    )
  )

  val toggleMenuElement = {
    <a id="toggleMenuButton" class="sidebar-toggle p-3" role="button">
      <i class="fa fa-bars"></i>
      <span class="visually-hidden">Toggle navigation</span>
    </a>
  }
}
