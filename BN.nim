# Nim wrapper around the imath C library.

# Compile the C file.
{.compile: "BN/imath.c".}
# Compile the stringify wrapper.
{.compile: "BN/wrapper.c".}

import strutils, math

type
  # Direct copy of the imath BN struct.
  mpz_t = object
    single: cuint
    digits: ptr cuint
    alloc: cuint
    used: cuint
    sign: cuchar

  mp_result = enum
    MP_BADARG = -6 # invalid null argument
    MP_TRUNC  = -5 # output truncated
    MP_UNDEF  = -4 # result undefined
    MP_RANGE  = -3 # argument out of range
    MP_MEMORY = -2 # out of memory
    MP_TRUE   = -1 # boolean true
    MP_FALSE  = 0  # boolean false

  # Wrapper object.
  BN* = ref object of RootObj
    number: mpz_t

  # Some basic numbers to stop hard coded BN literals.
  BNNumsType* = ref object of RootObj
    ZERO*: BN
    ONE*: BN
    TWO*: BN
    TEN*: BN
    SIXTEEN*: BN
    FIFTYEIGHT*: BN

{.push cdecl.}
# C 'destructor'.
proc mpz_tClear(z: ptr mpz_t) {.importc: "mp_int_clear".}
# C 'constructor'.
proc mpz_tInit(x: ptr mpz_t, base: cint, value: cstring): mp_result {.importc: "mp_int_read_string".}
# Stringify function.
proc mpz_tStringify(x: ptr mpz_t): cstring {.importc: "printMPZ_T".}
# Addition  function.
proc mpz_tAdd(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t): mp_result {.importc: "mp_int_add".}
# Subtraction functions.
proc mpz_tSub(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t): mp_result {.importc: "mp_int_sub".}
# Multiplication functions.
proc mpz_tMul(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t): mp_result {.importc: "mp_int_mul".}
# Exponent/power functions.
proc mpz_tPow(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t): mp_result {.importc: "mp_int_expt_full".}
# Division functions.
proc mpz_tDiv(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t, r: ptr mpz_t): mp_result {.importc: "mp_int_div".}
# Modulus functions.
proc mpz_tMod(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t): mp_result {.importc: "mp_int_mod".}
# All the comparison functions. ==, !-, <, <=, >, and >=.
proc mpz_tCompare(x: ptr mpz_t, y: ptr mpz_t): cint {.importc: "mp_int_compare".}
# Get errors  
proc mpz_tErrorString(res: mp_result): cstring {.importc: "mp_error_string".}
{.pop.}

template raiseResult(res: mp_result): untyped = 
  case res:
    of MP_FALSE, MP_TRUE, MP_TRUNC: discard
    of MP_BADARG:
      raise newException(ValueError, $mpz_tErrorString(res))
    of MP_UNDEF:
      raise newException(DivByZeroError, $mpz_tErrorString(res))
    of MP_RANGE:
      raise newException(RangeError, $mpz_tErrorString(res))
    of MP_MEMORY:
      raise newException(OutOfMemError, $mpz_tErrorString(res))

# Nim destructor.
proc destroyBN(z: BN) {.raises: [].} =
  if not z.isNil:
    mpz_tClear(z.number.addr)

# Nim constructors.
proc newBN*(numberArg: string = "0"): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result.new(destroyBN)
  raiseResult mpz_tInit(addr result.number, 10, unsafeAddr numberArg[0])

proc newBN*(number: SomeInteger): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN($number)

# Define some basic numbers.
var BNNums*: BNNumsType = BNNumsType(
  ZERO: newBN("0"),
  ONE: newBN("1"),
  TWO: newBN("2"),
  TEN: newBN("10"),
  SIXTEEN: newBN("16"),
  FIFTYEIGHT: newBN("58")
)

proc `$`*(x: BN): string {.raises: [].} =
  result = $mpz_tStringify(addr x.number)

proc `+`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN()
  raiseResult mpz_tAdd(addr x.number, addr y.number, addr result.number)

# += operator.
proc `+=`*(x: BN, y: BN) {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x.number = (x + y).number

# Nim uses inc/dec instead of ++ and --. This is when BNNums is useful as hell.
proc inc*(x: BN) {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x += BNNums.ONE

proc `-`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN()
  raiseResult mpz_tSub(addr x.number, addr y.number, addr result.number)

proc `-=`*(x: BN, y: BN) {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x.number = (x - y).number

proc dec*(x: BN) {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x -= BNNums.ONE

proc `*`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN()
  raiseResult mpz_tMul(addr x.number, addr y.number, addr result.number)

proc `*=`*(x: BN, y: BN) {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x.number = (x * y).number

proc `^`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN()
  raiseResult mpz_tPow(addr x.number, addr y.number, addr result.number)

proc `pow`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x ^ y

proc `/`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN()
  # imath also returns the remainder. We don't use it, hence the junk `addr newBN().number`.
  raiseResult mpz_tDiv(addr x.number, addr y.number, addr result.number, addr newBN().number)

proc `div`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x / y

proc `//`*(x: BN, y: BN): tuple[result: BN, remainder: BN] {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result.result = newBN()
  result.remainder = newBN()
  raiseResult mpz_tDiv(addr x.number, addr y.number, addr result.result.number, addr result.remainder.number)

proc `divWRemainder`*(x: BN, y: BN): tuple[result: BN, remainder: BN] {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x // y

proc `%`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  result = newBN()
  raiseResult mpz_tMod(addr x.number, addr y.number, addr result.number)

proc `mod`*(x: BN, y: BN): BN {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError].} =
  x % y

proc `==`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(addr x.number, addr y.number) == 0

proc `!=`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(addr x.number, addr y.number) != 0

proc `<`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(addr x.number, addr y.number) < 0

proc `<=`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(addr x.number, addr y.number) < 1

proc `>`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(addr x.number, addr y.number) > 0

proc `>=`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(addr x.number, addr y.number) > -1

# To int function.
proc toInt*(x: BN): int {.raises: [ValueError, DivByZeroError, RangeError, OutOfMemError, OverflowError].} =
  if x > newBN(int.high):
    raise newException(ValueError, "BN is too big to be converted to an int.")
  parseInt($x)
