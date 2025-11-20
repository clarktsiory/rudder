package com.normation.rudder

import org.junit.runner.RunWith
import zio.Tag
import zio.json.DeriveJsonCodec
import zio.json.EncoderOps
import zio.json.JsonCodec
import zio.json.golden.*
import zio.test.*
import zio.test.Assertion.*
import zio.test.junit.ZTestJUnitRunner
import zio.test.magnolia.DeriveGen

@RunWith(classOf[ZTestJUnitRunner])
class CodecMigrationTest extends ZIOSpecDefault {

  case class Point(x: Int, y: Int)
  case class Virgule(x: Int, y: Int)

  val genPoint:   Gen[Any, Point]   = DeriveGen[Point]
  val genVirgule: Gen[Any, Virgule] = DeriveGen[Virgule]

  trait LiftJson[A] {
    def encode(a: A): String
  }

  given JsonCodec[Point] = DeriveJsonCodec.gen

  given LiftJson[Point] = point => s"""{"x":${point.x},"y":${point.y}}"""

  given JsonCodec[Virgule] = DeriveJsonCodec.gen

  given LiftJson[Virgule] = point => s"""{"x":${point.x},"y":${point.y}}"""

  def testMigration[A](gen: Gen[Any, A])(using codec: JsonCodec[A], lift: LiftJson[A], tag: Tag[A]) = {
    test(s"${tag.tag.shortName}") {
      check(gen) { instance =>
        val liftJson = lift.encode(instance)
        val zioJson  = instance.toJson

        assert(liftJson)(equalTo(zioJson))
      }
    }
  }

  val spec = suiteAll("test JSON for Point and Virgule") {
    suite("encoding with zio-json should output exactly the same json than with liftweb-json")(
      testMigration(genPoint),
      testMigration(genVirgule)
    )
    suite("golden test for zio-json")(
      goldenTest(genPoint),
      goldenTest(genVirgule)
    )
  }

}
