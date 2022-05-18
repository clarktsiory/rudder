/*
*************************************************************************************
* Copyright 2017 Normation SAS
*************************************************************************************
*
* This file is part of Rudder.
*
* Rudder is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* In accordance with the terms of section 7 (7. Additional Terms.) of
* the GNU General Public License version 3, the copyright holders add
* the following Additional permissions:
* Notwithstanding to the terms of section 5 (5. Conveying Modified Source
* Versions) and 6 (6. Conveying Non-Source Forms.) of the GNU General
* Public License version 3, when you create a Related Module, this
* Related Module is not considered as a part of the work and may be
* distributed under the license agreement of your choice.
* A "Related Module" means a set of sources files including their
* documentation that, without modification of the Source Code, enables
* supplementary functions or services in addition to those offered by
* the Software.
*
* Rudder is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with Rudder.  If not, see <http://www.gnu.org/licenses/>.

*
*************************************************************************************
*/

package com.normation.rudder.rest.lift

import com.normation.inventory.domain.NodeId
import com.normation.rudder.domain.policies.{Directive, DirectiveId, Rule, RuleId}
import com.normation.rudder.domain.reports.{ComplianceLevel, ComponentStatusReport, DirectiveStatusReport}
import com.normation.rudder.reports.GlobalComplianceMode
import com.normation.rudder.repository.{FullActiveTechnique, RoDirectiveRepository, RoNodeGroupRepository, RoRuleRepository}
import com.normation.rudder.rest.ApiVersion
import com.normation.rudder.rest.RestExtractorService
import com.normation.rudder.rest.RestUtils._
import com.normation.rudder.rest._
import com.normation.rudder.rest.data._
import com.normation.rudder.rest.{ComplianceApi => API}
import com.normation.rudder.services.nodes.NodeInfoService
import com.normation.rudder.services.reports.ReportingService
import net.liftweb.common._
import net.liftweb.http.LiftResponse
import net.liftweb.http.Req
import net.liftweb.json.JsonDSL._
import net.liftweb.json._
import com.normation.box._

import scala.collection.immutable

class ComplianceApi(
    restExtractorService: RestExtractorService
  , complianceService   : ComplianceAPIService
) extends LiftApiModuleProvider[API] {

  import JsonCompliance._

  def schemas = API

  /*
   * The actual builder for the compliance API.
   * Depends of authz method and supported version.
   *
   * It's quite verbose, but it's the only way I found to
   * get the exhaustivity check and be sure that ALL
   * endpoints are processed.
   */
  def getLiftEndpoints(): List[LiftApiModule] = {
    API.endpoints.map(e => e match {
        case API.GetRulesCompliance   => GetRules
        case API.GetRulesComplianceId => GetRuleId
        case API.GetNodesCompliance   => GetNodes
        case API.GetNodeComplianceId  => GetNodeId
        case API.GetGlobalCompliance  => GetGlobal
    }).toList
  }


  object GetRules extends LiftApiModule0 {
    val schema = API.GetRulesCompliance
    val restExtractor = restExtractorService
    def process0(version: ApiVersion, path: ApiPath, req: Req, params: DefaultParams, authzToken: AuthzToken): LiftResponse = {
      implicit val action = schema.name
      implicit val prettify = params.prettify

      (for {
        level <- restExtractor.extractComplianceLevel(req.params)
        computeLevel <- Full(if(version.value <= 6) {
                          None
                        } else {
                          level
                        })
        rules <- complianceService.getRulesCompliance(computeLevel)
      } yield {
        if(version.value <= 6) {
          rules.map( _.toJsonV6 )
        } else {
          rules.map( _.toJson(level.getOrElse(10) ) ) //by default, all details are displayed
        }
      }) match {
        case Full(rules) =>
          toJsonResponse(None, ( "rules" -> rules ) )

        case eb: EmptyBox =>
          val message = (eb ?~ (s"Could not get compliance for all rules")).messageChain
          toJsonError(None, JString(message))
      }
    }
  }

  object GetRuleId extends LiftApiModule {
    val schema = API.GetRulesComplianceId
    val restExtractor = restExtractorService
    def process(version: ApiVersion, path: ApiPath, ruleId: String, req: Req, params: DefaultParams, authzToken: AuthzToken): LiftResponse = {
      implicit val action = schema.name
      implicit val prettify = params.prettify

      (for {
        level <- restExtractor.extractComplianceLevel(req.params)
        rule  <- complianceService.getRuleCompliance(RuleId(ruleId), level)
      } yield {
        if(version.value <= 6) {
          rule.toJsonV6
        } else {
          rule.toJson(level.getOrElse(10) ) //by default, all details are displayed
        }
      }) match {
        case Full(rule) =>
          toJsonResponse(None,( "rules" -> List(rule) ) )

        case eb: EmptyBox =>
          val message = (eb ?~ (s"Could not get compliance for rule '${ruleId}'")).messageChain
          toJsonError(None, JString(message))
      }
    }
  }

  object GetNodes extends LiftApiModule0 {
    val schema = API.GetNodesCompliance
    val restExtractor = restExtractorService
    def process0(version: ApiVersion, path: ApiPath, req: Req, params: DefaultParams, authzToken: AuthzToken): LiftResponse = {
      implicit val action = schema.name
      implicit val prettify = params.prettify

      (for {
        level <- restExtractor.extractComplianceLevel(req.params)
        nodes <- complianceService.getNodesCompliance()
      } yield {
        if(version.value <= 6) {
          nodes.map( _.toJsonV6 )
        } else {
          nodes.map( _.toJson(level.getOrElse(10)) )
        }
      })match {
        case Full(nodes) =>
          toJsonResponse(None, ("nodes" -> nodes ) )

        case eb: EmptyBox =>
          val message = (eb ?~ ("Could not get compliances for nodes")).messageChain
          toJsonError(None, JString(message))
      }
    }
  }

  object GetNodeId extends LiftApiModule {
    val schema = API.GetNodeComplianceId
    val restExtractor = restExtractorService
    def process(version: ApiVersion, path: ApiPath, nodeId: String, req: Req, params: DefaultParams, authzToken: AuthzToken): LiftResponse = {
      implicit val action = schema.name
      implicit val prettify = params.prettify

      (for {
        level <- restExtractor.extractComplianceLevel(req.params)
        node  <- complianceService.getNodeCompliance(NodeId(nodeId))
      } yield {
        if(version.value <= 6) {
          node.toJsonV6
        } else {
          node.toJson(level.getOrElse(10))
        }
      })match {
        case Full(node) =>
          toJsonResponse(None, ("nodes" -> List(node) ))

        case eb: EmptyBox =>
          val message = (eb ?~ (s"Could not get compliance for node '${nodeId}'")).messageChain
          toJsonError(None, JString(message))
      }
    }
  }

  object GetGlobal extends LiftApiModule0 {
    val schema = API.GetGlobalCompliance
    val restExtractor = restExtractorService
    def process0(version: ApiVersion, path: ApiPath, req: Req, params: DefaultParams, authzToken: AuthzToken): LiftResponse = {
      implicit val action = schema.name
      implicit val prettify = params.prettify

      (for {
        optCompliance <- complianceService.getGlobalCompliance()
      } yield {
        optCompliance.toJson
      }) match {
        case Full(json) =>
          toJsonResponse(None, json)

        case eb: EmptyBox =>
          val message = (eb ?~ (s"Could not get global compliance (for non system rules)")).messageChain
          toJsonError(None, JString(message))
      }
    }
  }
}


/**
 * The class in charge of getting and calculating
 * compliance for all rules/nodes/directives.
 */
class ComplianceAPIService(
    rulesRepo       : RoRuleRepository
  , nodeInfoService : NodeInfoService
  , nodeGroupRepo   : RoNodeGroupRepository
  , reportingService: ReportingService
  , directiveRepo   : RoDirectiveRepository
  , val getGlobalComplianceMode: () => Box[GlobalComplianceMode]
) extends Loggable {

  /**
   * Get the compliance for everything
   * level is optionnally the selected level.
   * level 1 includes rules but not directives
   * level 2 includes directives, but not component
   * level 3 includes components, but not nodes
   * level 4 includes the nodes
   */
 private[this] def getByRulesCompliance(rules: Seq[Rule], level: Option[Int]) : Box[Seq[ByRuleRuleCompliance]] = {
    val computedLevel = level.getOrElse(10)
    val t1 = System.currentTimeMillis()
    for {
      allGroups      <- nodeGroupRepo.getAllNodeIds().toBox
      t2             = System.currentTimeMillis()
      _              = logger.trace(s"getByRulesCompliance - getFullGroupLibrary in ${t2 - t1} ms")

      // this can be optimized, as directive only happen for level=2
      directives    <- if (computedLevel >= 2 ) {
                         directiveRepo.getFullDirectiveLibrary().toBox.map(_ . allDirectives )
                       } else {
                         Full(Map[DirectiveId, (FullActiveTechnique, Directive)]())
                       }
      t3             = System.currentTimeMillis()
      _              = logger.trace(s"getByRulesCompliance - getFullDirectiveLibrary in ${t3 - t2} ms")

      nodeInfos     <- nodeInfoService.getAll()
      t4             = System.currentTimeMillis()
      _              = logger.trace(s"getByRulesCompliance - nodeInfoService.getAll() in ${t4 - t3} ms")

      compliance    <- getGlobalComplianceMode()
      t5             = System.currentTimeMillis()
      _              = logger.trace(s"getByRulesCompliance - getGlobalComplianceMode in ${t5 - t4} ms")


      ruleObjects   = rules.map { case x => (x.id, x) }.toMap
      reportsByNode <- reportingService.findRuleNodeStatusReports(
                         nodeInfos.keySet, ruleObjects.keySet
                       )
      t6             = System.currentTimeMillis()
      _              = logger.trace(s"getByRulesCompliance - findRuleNodeStatusReports in ${t6 - t5} ms")
    } yield {  //flatMap of Set is ok, since nodeRuleStatusReport are different for different nodeIds

      val reportsByRule  = reportsByNode.flatMap { case(_, status) => status.reports }.groupBy( _.ruleId)
      val t7             = System.currentTimeMillis()
      logger.trace(s"getByRulesCompliance - group reports by rules in ${t7 - t6} ms")

      //for each rule for each node, we want to have a
      //directiveId -> reporttype map
      val nonEmptyRules  = reportsByRule.toSeq.map { case (ruleId, reports) =>
                //aggregate by directives, if level is at least 2
                val byDirectives: Map[DirectiveId, immutable.Iterable[(NodeId, DirectiveStatusReport)]] = if (computedLevel < 2) {
                  Map()
                } else {
                  reports.flatMap { r => r.directives.values.map(d => (r.nodeId, d)).toSeq }.groupBy( _._2.directiveId)
                }


                ByRuleRuleCompliance(
                  ruleId
                  , ruleObjects.get(ruleId).map(_.name).getOrElse("Unknown rule")
                  , ComplianceLevel.sum(reports.map(_.compliance))
                  , compliance.mode
                  , byDirectives.map{ case (directiveId, nodeDirectives) =>
                    ByRuleDirectiveCompliance(
                      directiveId
                      , directives.get(directiveId).map(_._2.name).getOrElse("Unknown directive")
                      , ComplianceLevel.sum(nodeDirectives.map( _._2.compliance) )
                      , //here we want the compliance by components of the directive.
                      // if level is high enough, get all components and group by their name
                      {
                        val byComponents:  Map[String, immutable.Iterable[(NodeId, ComponentStatusReport)]] = if (computedLevel < 3) {
                          Map()
                        } else {
                          nodeDirectives.flatMap { case (nodeId, d) => d.components.values.map(c => (nodeId, c)).toSeq }.groupBy( _._2.componentName )
                        }

                        byComponents.map { case (name, nodeComponents) =>
                          ByRuleComponentCompliance(
                            name
                            , ComplianceLevel.sum( nodeComponents.map(_._2.compliance))
                            , //here, we finally group by nodes for each components if level is high enough
                            {
                              val byNode = nodeComponents.groupBy(_._1)
                              byNode.map { case (nodeId, components) =>
                                ByRuleNodeCompliance(
                                  nodeId
                                  , nodeInfos.get(nodeId).map(_.hostname).getOrElse("Unknown node")
                                  , components.map(_._2).toSeq.sortBy(_.componentName).flatMap(_.componentValues.values)
                                )
                              }.toSeq
                            }
                          )
                        }.toSeq
                      }
                    )
                  }.toSeq
                )

              }
      val t8        = System.currentTimeMillis()
      logger.trace(s"getByRulesCompliance - Compute non empty rules in ${t8 - t7} ms")


      // if any rules is in the list in parameter an not in the nonEmptyRules, then it means
      // there's no compliance for it, so it's empty
      // we need to set the ByRuleCompliance with a compliance of NoAnswer
      val rulesWithoutCompliance = ruleObjects.keySet -- reportsByRule.keySet


      val initializedCompliances : Seq[ByRuleRuleCompliance] = {
        if (rulesWithoutCompliance.isEmpty) {
          Seq[ByRuleRuleCompliance]()
        } else {
          rulesWithoutCompliance.toSeq.map { case ruleId =>
            val rule = ruleObjects(ruleId) // we know by construct that it exists
            val nodeIds = RoNodeGroupRepository.getNodeIds(allGroups, rule.targets, nodeInfos)
            ByRuleRuleCompliance(
                rule.id
                , rule.name
                , ComplianceLevel(noAnswer = nodeIds.size)
                , compliance.mode
                , Seq()
              )
            }
          }
        }

      val t9 = System.currentTimeMillis()
      logger.trace(s"getByRulesCompliance - Compute ${initializedCompliances.size} empty rules in ${t9 - t8} ms")

      //return the full list
      val result = nonEmptyRules ++ initializedCompliances

      val t10 = System.currentTimeMillis()
      logger.trace(s"getByRulesCompliance - Compute result in ${t10 - t9} ms")
      result
    }
  }

  def getRuleCompliance(ruleId: RuleId, level: Option[Int]): Box[ByRuleRuleCompliance] = {
    for {
      rule    <- rulesRepo.get(ruleId).toBox
      reports <- getByRulesCompliance(Seq(rule), level)
      report  <- Box(reports.find( _.id == ruleId)) ?~! s"No reports were found for rule with ID '${ruleId.value}'"
    } yield {
      report
    }
  }

  def getRulesCompliance(level: Option[Int]): Box[Seq[ByRuleRuleCompliance]] = {
    for {
      rules   <- rulesRepo.getAll().toBox
      reports <- getByRulesCompliance(rules, level)
    } yield {
      reports
    }
  }

  /**
   * Get the compliance for everything
   */
  private[this] def getByNodesCompliance(onlyNode: Option[NodeId]): Box[Seq[ByNodeNodeCompliance]] = {

    for {
      rules        <- rulesRepo.getAll().toBox
      allGroups    <- nodeGroupRepo.getAllNodeIds().toBox
      directiveLib <- directiveRepo.getFullDirectiveLibrary().map(_.allDirectives).toBox
      allNodeInfos <- nodeInfoService.getAll()
      nodeInfos    <- onlyNode match {
                        case None => Full(allNodeInfos)
                        case Some(id) => Box(allNodeInfos.get(id)).map(info => Map(id -> info)) ?~! s"The node with ID '${id.value}' is not known on Rudder"
                      }
      compliance   <- getGlobalComplianceMode()
      reports      <- reportingService.findRuleNodeStatusReports(
                        nodeInfos.keySet, rules.map(_.id).toSet
                      )
    } yield {

      //get nodeIds by rules
      val nodeByRules = rules.map { rule =>
        (rule, RoNodeGroupRepository.getNodeIds(allGroups, rule.targets, allNodeInfos) )
      }

      val ruleMap = rules.map(r => (r.id,r)).toMap
      // get an empty-initialized array of compliances to be used
      // as defaults
      val initializedCompliances : Map[NodeId, ByNodeNodeCompliance] = {
        nodeInfos.map { case (nodeId, nodeInfo) =>
          val rulesForNode = nodeByRules.collect { case (rule, nodeIds) if(nodeIds.contains(nodeId)) => rule }

          (nodeId, ByNodeNodeCompliance(
              nodeId
            , nodeInfos.get(nodeId).map(_.hostname).getOrElse("Unknown node")
            , ComplianceLevel(noAnswer = rulesForNode.size)
            , compliance.mode
            , (rulesForNode.map { rule =>
                ByNodeRuleCompliance(
                    rule.id
                  , rule.name
                  , ComplianceLevel(noAnswer = rule.directiveIds.size)
                  , rule.directiveIds.map { id => ByNodeDirectiveCompliance(id, directiveLib.get(id).map(_._2.name).getOrElse("Unknown Directive"), ComplianceLevel(noAnswer = 1), Map())}.toSeq
                )
              }).toSeq
          ))
        }.toMap
      }

      //for each rule for each node, we want to have a
      //directiveId -> reporttype map
      val nonEmptyNodes = reports.map { case (nodeId, status) =>
        (
          nodeId,
          ByNodeNodeCompliance(
              nodeId
            , nodeInfos.get(nodeId).map(_.hostname).getOrElse("Unknown node")
            , ComplianceLevel.sum(status.reports.map(_.compliance))
            , compliance.mode
            , status.reports.toSeq.map(r =>
               ByNodeRuleCompliance(
                    r.ruleId
                  , ruleMap.get(r.ruleId).map(_.name).getOrElse("Unknown rule")
                  , r.compliance
                  , r.directives.toSeq.map { case (_, directiveReport) => ByNodeDirectiveCompliance(directiveReport,directiveLib.get(directiveReport.directiveId).map(_._2.name).getOrElse("Unknown Directive")) }
                )
              )
          )
        )
      }.toMap

      //return the full list, even for non responding nodes/directives
      //but override with values when available.
      (initializedCompliances ++ nonEmptyNodes).values.toSeq

    }
  }

  def getNodeCompliance(nodeId: NodeId): Box[ByNodeNodeCompliance] = {
    for {
      reports <- this.getByNodesCompliance(Some(nodeId))
      report  <- Box(reports.find( _.id == nodeId)) ?~! s"No reports were found for node with ID '${nodeId.value}'"
    } yield {
      report
    }

  }

  def getNodesCompliance(): Box[Seq[ByNodeNodeCompliance]] = {
    this.getByNodesCompliance(None)
  }

  def getGlobalCompliance(): Box[Option[(ComplianceLevel, Long)]] = {
    this.reportingService.getGlobalUserCompliance()
  }
}

