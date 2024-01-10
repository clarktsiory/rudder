package com.normation.rudder.web.snippet

import net.liftweb.http.DispatchSnippet
import scala.xml.Elem
import scala.xml.MetaData
import scala.xml.Node
import scala.xml.NodeSeq
import scala.xml.Null
import scala.xml.UnprefixedAttribute

object WithNonce extends DispatchSnippet {
  def dispatch = { case _ => render }

  def render(xhtml: NodeSeq) = {
    val nonce = "8IBTHwOdqNKAWeKl7plt8g=="
    xhtml.map(scriptWithNonce(_)(nonce))
  }

  def scriptWithNonce(base: Node)(nonce: String) = {
    val attributes = MetaData.update(base.attributes, base.scope, new UnprefixedAttribute("nonce", nonce, Null))
    base match {
      case e: Elem => e.copy(attributes = attributes)
      case _ => base
    }
  }
}
