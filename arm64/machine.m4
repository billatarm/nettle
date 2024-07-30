dnl Support macros for
dnl   - Armv8.3-A Pointer Authentication and
dnl   - Armv8.5-A Branch Target Identification
dnl Further documentation can be found at:
dnl  - https://developer.arm.com/documentation/101028/0012/5--Feature-test-macros
dnl Note that the hint instrunctions are used which means that on older assemblers they will assemble
dnl  and that they are in the NOP space on older architectures and are NOP'd.
define(`bti_c', `hint #34')

dnl ASM_AARCH64_BTI_ENABLE - BTI Enabled
dnl GNU Notes section in ELF contain these values and can be read with readelf -n
dnl BTI Is required to be marked so the linker knows what mprotect flags to enable
dnl BTI is shown enabled in bit 0 and PAC in bit 1 for GNU Notes. This is required
dnl for the loader to set PROT_BTI on the shared library pages.
define(`GNU_PROPERTY_AARCH64_BTI',`ifelse(
  ASM_AARCH64_BTI_ENABLE, `1', `1',
  `0'dnl
  )'dnl
)

dnl ASM_AARCH64_PAC_A_ENABLE - PAC A Key Enabled (nothing to do as leaf functions)
dnl ASM_AARCH64_PAC_B_ENABLE - PAC B Key Enabled (nothing to do as leaf functions)
dnl GNU Notes PAC bit is a nice to have for auditing purposes and is located in bit 2.
dnl NOTE: Even though GNU Notes only marks PAC enabled or not and is agnostic, we'll
dnl keep the distinction between the A and B key so the plumbing is present if an
dnl asm routine ever needs to use pac instructions.
define(`GNU_PROPERTY_AARCH64_POINTER_AUTH', `ifelse(
  ASM_AARCH64_PAC_A_ENABLE, `1', `2',
  ASM_AARCH64_PAC_B_ENABLE, `1', `2',
  `0'dnl
  )'dnl
)

define(`bti_prologue', `ifelse(
  ASM_AARCH64_BTI_ENABLE, `1', `bti_c',
  )'
)

define(`PROLOGUE',
`.globl C_NAME($1)
DECLARE_FUNC(C_NAME($1))
C_NAME($1): bti_prologue')

C Get 32-bit floating-point register from vector register
C SFP(VR)
define(`SFP',``s'substr($1,1,len($1))')

C Get 128-bit floating-point register from vector register
C QFP(VR)
define(`QFP',``q'substr($1,1,len($1))')

C AES encryption round of 1-block
C AESE_ROUND_1B(BLOCK, KEY)
define(`AESE_ROUND_1B', m4_assert_numargs(2)`
    aese           $1.16b,$2.16b
    aesmc          $1.16b,$1.16b
')

C AES last encryption round of 1-block
C AESE_LAST_ROUND_1B(BLOCK, KEY0, KEY1)
define(`AESE_LAST_ROUND_1B', m4_assert_numargs(3)`
    aese           $1.16b,$2.16b
    eor            $1.16b,$1.16b,$3.16b
')

C AES decryption round of 1-block
C AESD_ROUND_1B(BLOCK, KEY)
define(`AESD_ROUND_1B', m4_assert_numargs(2)`
    aesd           $1.16b,$2.16b
    aesimc         $1.16b,$1.16b
')

C AES last decryption round of 1-block
C AESD_LAST_ROUND_1B(BLOCK, KEY0, KEY1)
define(`AESD_LAST_ROUND_1B', m4_assert_numargs(3)`
    aesd           $1.16b,$2.16b
    eor            $1.16b,$1.16b,$3.16b
')

C AES encryption round of 4-blocks
C AESE_ROUND_4B(BLOCK0, BLOCK1, BLOCK2, BLOCK3, KEY)
define(`AESE_ROUND_4B', m4_assert_numargs(5)`
    AESE_ROUND_1B($1,$5)
    AESE_ROUND_1B($2,$5)
    AESE_ROUND_1B($3,$5)
    AESE_ROUND_1B($4,$5)
')

C AES last encryption round of 4-blocks
C AESE_LAST_ROUND_4B(BLOCK0, BLOCK1, BLOCK2, BLOCK3, KEY0, KEY1)
define(`AESE_LAST_ROUND_4B', m4_assert_numargs(6)`
    AESE_LAST_ROUND_1B($1,$5,$6)
    AESE_LAST_ROUND_1B($2,$5,$6)
    AESE_LAST_ROUND_1B($3,$5,$6)
    AESE_LAST_ROUND_1B($4,$5,$6)
')

C AES decryption round of 4-blocks
C AESD_ROUND_4B(BLOCK0, BLOCK1, BLOCK2, BLOCK3, KEY)
define(`AESD_ROUND_4B', m4_assert_numargs(5)`
    AESD_ROUND_1B($1,$5)
    AESD_ROUND_1B($2,$5)
    AESD_ROUND_1B($3,$5)
    AESD_ROUND_1B($4,$5)
')

C AES last decryption round of 4-blocks
C AESD_LAST_ROUND_4B(BLOCK0, BLOCK1, BLOCK2, BLOCK3, KEY0, KEY1)
define(`AESD_LAST_ROUND_4B', m4_assert_numargs(6)`
    AESD_LAST_ROUND_1B($1,$5,$6)
    AESD_LAST_ROUND_1B($2,$5,$6)
    AESD_LAST_ROUND_1B($3,$5,$6)
    AESD_LAST_ROUND_1B($4,$5,$6)
')

ifelse(ASM_IS_ELF, `1', `
  .pushsection .note.gnu.property, "a";
  .balign 8;
  .long 4;
  .long 0x10;
  .long 0x5;
  .asciz "GNU";
  .long 0xc0000000; /* GNU_PROPERTY_AARCH64_FEATURE_1_AND */
  .long 4;
  .long(GNU_PROPERTY_AARCH64_POINTER_AUTH | GNU_PROPERTY_AARCH64_BTI);
  .long 0;
  .popsection;
')
