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
proc mpz_tFree(z: ptr mpz_t) {.importc: "mp_int_free".}
# C 'constructor'.
proc mpz_tInit(x: ptr mpz_t, base: cint, value: cstring) {.importc: "mp_int_read_string".}
# Stringify function.
proc mpz_tStringify(x: ptr mpz_t): cstring {.importc: "printMPZ_T".}
# Addition  function.
proc mpz_tAdd(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t) {.importc: "mp_int_add".}
# Subtraction functions.
proc mpz_tSub(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t) {.importc: "mp_int_sub".}
# Multiplication functions.
proc mpz_tMul(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t) {.importc: "mp_int_mul".}
# Exponent/power functions.
proc mpz_tPow(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t) {.importc: "mp_int_expt_full".}
# Division functions.
proc mpz_tDiv(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t, r: ptr mpz_t) {.importc: "mp_int_div".}
# Modulus functions.
proc mpz_tMod(x: ptr mpz_t, y: ptr mpz_t, z: ptr mpz_t) {.importc: "mp_int_mod".}
# All the comparison functions. ==, !-, <, <=, >, and >=.
proc mpz_tCompare(x: mpz_t, y: mpz_t): cint {.importc: "mp_int_compare".}
{.pop.}

# Nim destructor.
proc destroyBN(z: BN) {.raises: [].} =
  mpz_tFree(z.number.addr)

# Nim constructors.
proc newBN*(numberArg: string = "0"): BN {.raises: [].} =
  result.new(destroyBN)
  mpz_tInit(addr result.number, 10, unsafeAddr numberArg[0])

proc newBN*(number: SomeInteger): BN {.raises: [].} =
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

proc `+`*(x: BN, y: BN): BN {.raises: [].} =
  result = newBN()
  mpz_tAdd(addr x.number, addr y.number, addr result.number)

# += operator.
proc `+=`*(x: BN, y: BN) {.raises: [].} =
  x.number = (x + y).number

# Nim uses inc/dec instead of ++ and --. This is when BNNums is useful as hell.
proc inc*(x: BN) {.raises: [].} =
  x += BNNums.ONE

proc `-`*(x: BN, y: BN): BN {.raises: [].} =
  result = newBN()
  mpz_tSub(addr x.number, addr y.number, addr result.number)

proc `-=`*(x: BN, y: BN) {.raises: [].} =
  x.number = (x - y).number

proc dec*(x: BN) {.raises: [].} =
  x -= BNNums.ONE

proc `*`*(x: BN, y: BN): BN {.raises: [].} =
  result = newBN()
  mpz_tMul(addr x.number, addr y.number, addr result.number)

proc `*=`*(x: BN, y: BN) {.raises: [].} =
  x.number = (x * y).number

proc `^`*(x: BN, y: BN): BN {.raises: [].} =
  result = newBN()
  mpz_tPow(addr x.number, addr y.number, addr result.number)

proc `pow`*(x: BN, y: BN): BN {.raises: [].} =
  x ^ y

proc `/`*(x: BN, y: BN): BN {.raises: [].} =
  result = newBN()
  # imath also returns the remainder. We don't use it, hence the junk `addr newBN().number`.
  mpz_tDiv(addr x.number, addr y.number, addr result.number, addr newBN().number)

proc `div`*(x: BN, y: BN): BN {.raises: [].} =
  x / y

proc `//`*(x: BN, y: BN): tuple[result: BN, remainder: BN] {.raises: [].} =
  result.result = newBN()
  result.remainder = newBN()
  mpz_tDiv(addr x.number, addr y.number, addr result.result.number, addr result.remainder.number)

proc `divWRemainder`*(x: BN, y: BN): tuple[result: BN, remainder: BN] {.raises: [].} =
  x // y

proc `%`*(x: BN, y: BN): BN {.raises: [].} =
  result = newBN()
  mpz_tMod(addr x.number, addr y.number, addr result.number)

proc `mod`*(x: BN, y: BN): BN {.raises: [].} =
  x % y

proc `==`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(x.number, y.number) == 0

proc `!=`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(x.number, y.number) != 0

proc `<`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(x.number, y.number) < 0

proc `<=`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(x.number, y.number) < 1

proc `>`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(x.number, y.number) > 0

proc `>=`*(x: BN, y: BN): bool {.raises: [].} =
  mpz_tCompare(x.number, y.number) > -1

# To int function.
proc toInt*(x: BN): int {.raises: [ValueError, OverflowError].} =
  if x > newBN(int.high):
    raise newException(ValueError, "BN is too big to be converted to an int.")
  parseInt($x)
