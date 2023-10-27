package com.normation.rudder.rest

object RestValidation {

  def toMinimalSizeString(minimalSize: Int)(value: String): Either[String, String] = {
    Either.cond(
      value.size >= minimalSize,
      value,
      s"$value must be at least have a ${minimalSize} character size"
    )
  }

}
