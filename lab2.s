@ ===========================================================
@ CS413 Lab 2 - ARM Stack Program
@ Areas of Plane Shapes Calculator
@ Lab2 Set_5
@
@ Term:    Spring 2026
@ Author:  Student
@ Date:    2026-02-28
@
@ Purpose: This ARM assembly program calculates the area of
@          four plane shapes: Triangle, Rectangle, Trapezoid,
@          and Square. It uses stack-based parameter passing
@          (PUSH/POP) to subroutines for each area formula.
@          All inputs and outputs are unsigned 32-bit integers.
@          Overflow is detected and reported to the user.
@
@ Assemble: as -o lab2.o lab2.s
@ Link:     gcc -o lab2 lab2.o
@ Run:      ./lab2
@ Debug:    gdb ./lab2
@
@ Area Formulas:
@   Triangle:  area = (base * height) / 2
@   Rectangle: area = length * width
@   Trapezoid: area = (a + b) * height / 2
@   Square:    area = side * side
@
@ Register Usage Convention:
@   Main routine uses r4, r5, r6 to hold operands.
@   Subroutines pop into r7, r10, r11 for computation.
@   This ensures different registers are used in caller
@   vs callee, demonstrating proper stack parameter passing.
@ ===========================================================

.data

@ --- Welcome and Instruction Message ---
welcome_msg:
    .asciz "\n=========================================\n  Welcome to the Area Calculator!\n\n  This program calculates the area of:\n    - Triangle\n    - Rectangle\n    - Trapezoid\n    - Square\n\n  You will be prompted to enter positive\n  integers for each calculation.\n=========================================\n"

@ --- Main Menu ---
menu_msg:
    .asciz "\n--- Main Menu ---\n1) Triangle\n2) Rectangle\n3) Trapezoid\n4) Square\n5) Quit\nEnter your choice (1-5): "

@ --- Input Prompts for Each Shape ---
prompt_base:
    .asciz "Enter the base (positive integer): "
prompt_height:
    .asciz "Enter the height (positive integer): "
prompt_length:
    .asciz "Enter the length (positive integer): "
prompt_width:
    .asciz "Enter the width (positive integer): "
prompt_side_a:
    .asciz "Enter side a (positive integer): "
prompt_side_b:
    .asciz "Enter side b (positive integer): "
prompt_side:
    .asciz "Enter the side length (positive integer): "

@ --- Output Messages ---
result_msg:
    .asciz "\nThe area is %u square units.\n"
overflow_msg:
    .asciz "\nError: Overflow! The result exceeds the 32-bit unsigned integer limit.\n"

@ --- Error Messages ---
err_choice:
    .asciz "\nError: Invalid choice. Please enter a number between 1 and 5.\n"
err_input:
    .asciz "\nError: Invalid input. Please enter a positive integer.\n"

@ --- Continue / Quit Messages ---
continue_msg:
    .asciz "\nWould you like to perform another calculation?\n1) Yes\n2) No\nEnter choice (1-2): "
goodbye_msg:
    .asciz "\nThank you for using the Area Calculator. Goodbye!\n"

@ --- Format String for scanf ---
fmt_int:
    .asciz "%d"

@ --- Variable for scanf to store input ---
    .balign 4
input_var:
    .word 0

.text
.global main
.extern printf
.extern scanf
.extern getchar

@ ===========================================================
@ main: Program entry point
@
@ Displays the welcome message, then enters the main loop
@ which shows the menu, reads the user's choice, collects
@ the appropriate inputs, calls the area subroutine via
@ stack-based parameter passing, and displays the result.
@ ===========================================================
main:
    PUSH {r4-r8, lr}               @ Save callee-saved registers and LR

    @ --- Display the welcome / instruction message ---
    LDR r0, =welcome_msg
    BL printf

@ ===========================================================
@ main_menu: Displays the menu and reads the user's choice.
@ Validates that the choice is an integer in range [1, 5].
@ ===========================================================
main_menu:
    LDR r0, =menu_msg
    BL printf

    @ --- Read the user's menu choice ---
    LDR r0, =fmt_int
    LDR r1, =input_var
    BL scanf

    @ Check if scanf successfully read an integer
    CMP r0, #1
    BNE menu_scanf_fail             @ scanf did not read an integer

    @ Check for trailing non-newline characters (e.g., "3.14")
    BL getchar
    CMP r0, #10                     @ Compare with '\n'
    BNE menu_trail_err              @ Non-newline char follows the number

    @ Load the integer value into r4
    LDR r4, =input_var
    LDR r4, [r4]

    @ Validate range [1, 5]
    CMP r4, #1
    BLT menu_range_err
    CMP r4, #5
    BGT menu_range_err

    @ --- Check if user chose Quit (option 5) ---
    CMP r4, #5
    BEQ exit_program

    @ --- Branch to the appropriate shape handler ---
    CMP r4, #1
    BEQ do_triangle
    CMP r4, #2
    BEQ do_rectangle
    CMP r4, #3
    BEQ do_trapezoid
    CMP r4, #4
    BEQ do_square

    B main_menu                     @ Safety fallback (should not reach)

@ --- Menu error handlers ---

@ scanf failed to read an integer (e.g., user entered "abc")
menu_scanf_fail:
    BL flush_input                  @ Clear invalid characters from stdin
    LDR r0, =err_choice
    BL printf
    B main_menu

@ Trailing non-newline character after integer (e.g., "3.14")
menu_trail_err:
    BL flush_input                  @ Clear remaining characters
    LDR r0, =err_choice
    BL printf
    B main_menu

@ Integer out of valid range [1, 5]
menu_range_err:
    LDR r0, =err_choice
    BL printf
    B main_menu

@ ===========================================================
@ TRIANGLE HANDLER
@
@ Prompts user for base and height, pushes them onto the
@ stack, calls triangle_area subroutine, and displays the
@ result or an overflow error.
@ Formula: area = (base * height) / 2
@ ===========================================================
do_triangle:
    @ Get base from user (validated positive integer)
    LDR r0, =prompt_base
    BL get_positive_int             @ Returns valid positive int in r0
    MOV r4, r0                      @ r4 = base

    @ Get height from user (validated positive integer)
    LDR r0, =prompt_height
    BL get_positive_int             @ Returns valid positive int in r0
    MOV r5, r0                      @ r5 = height

    @ --- Pass parameters via stack and call subroutine ---
    @ Main uses r4, r5; subroutine will pop into r10, r11
    PUSH {r4, r5}                   @ Push base and height onto stack
    BL triangle_area                @ Subroutine calculates area
    POP {r4, r5}                    @ r4 = result, r5 = overflow flag

    @ --- Display result or overflow error ---
    CMP r5, #0
    BNE show_overflow               @ If overflow flag is set, show error
    LDR r0, =result_msg
    MOV r1, r4                      @ Pass area value to printf
    BL printf
    B ask_continue

@ ===========================================================
@ RECTANGLE HANDLER
@
@ Prompts user for length and width, pushes them onto the
@ stack, calls rectangle_area subroutine, and displays the
@ result or an overflow error.
@ Formula: area = length * width
@ ===========================================================
do_rectangle:
    @ Get length from user
    LDR r0, =prompt_length
    BL get_positive_int
    MOV r4, r0                      @ r4 = length

    @ Get width from user
    LDR r0, =prompt_width
    BL get_positive_int
    MOV r5, r0                      @ r5 = width

    @ --- Pass parameters via stack and call subroutine ---
    PUSH {r4, r5}                   @ Push length and width
    BL rectangle_area               @ Subroutine calculates area
    POP {r4, r5}                    @ r4 = result, r5 = overflow flag

    @ --- Display result or overflow error ---
    CMP r5, #0
    BNE show_overflow
    LDR r0, =result_msg
    MOV r1, r4
    BL printf
    B ask_continue

@ ===========================================================
@ TRAPEZOID HANDLER
@
@ Prompts user for sides a, b and height, pushes them onto
@ the stack, calls trapezoid_area subroutine, and displays
@ the result or an overflow error.
@ Formula: area = (a + b) * height / 2
@ ===========================================================
do_trapezoid:
    @ Get side a from user
    LDR r0, =prompt_side_a
    BL get_positive_int
    MOV r4, r0                      @ r4 = side a

    @ Get side b from user
    LDR r0, =prompt_side_b
    BL get_positive_int
    MOV r5, r0                      @ r5 = side b

    @ Get height from user
    LDR r0, =prompt_height
    BL get_positive_int
    MOV r6, r0                      @ r6 = height

    @ --- Pass parameters via stack and call subroutine ---
    @ Push all three operands; subroutine pops 3, pushes 2
    PUSH {r4, r5, r6}              @ Push a, b, height
    BL trapezoid_area               @ Subroutine calculates area
    POP {r4, r5}                    @ r4 = result, r5 = overflow flag
    @ Stack is balanced: pushed 3 words (12 bytes),
    @ subroutine popped 3 and pushed 2, caller pops 2.
    @ Net SP change: -12 + 12 - 8 + 8 = 0

    @ --- Display result or overflow error ---
    CMP r5, #0
    BNE show_overflow
    LDR r0, =result_msg
    MOV r1, r4
    BL printf
    B ask_continue

@ ===========================================================
@ SQUARE HANDLER
@
@ Prompts user for the side length, pushes it onto the
@ stack, calls square_area subroutine, and displays the
@ result or an overflow error.
@ Formula: area = side * side
@ ===========================================================
do_square:
    @ Get side length from user
    LDR r0, =prompt_side
    BL get_positive_int
    MOV r4, r0                      @ r4 = side

    @ --- Pass parameter via stack and call subroutine ---
    @ Push one operand; subroutine pops 1, pushes 2
    PUSH {r4}                       @ Push side
    BL square_area                  @ Subroutine calculates area
    POP {r4, r5}                    @ r4 = result, r5 = overflow flag
    @ Stack is balanced: pushed 1 word (4 bytes),
    @ subroutine popped 1 and pushed 2, caller pops 2.
    @ Net SP change: -4 + 4 - 8 + 8 = 0

    @ --- Display result or overflow error ---
    CMP r5, #0
    BNE show_overflow
    LDR r0, =result_msg
    MOV r1, r4
    BL printf
    B ask_continue

@ ===========================================================
@ show_overflow: Displays the overflow error message.
@ ===========================================================
show_overflow:
    LDR r0, =overflow_msg
    BL printf
    @ Fall through to ask_continue

@ ===========================================================
@ ask_continue: Asks the user whether to continue with
@ another calculation or quit the program.
@ ===========================================================
ask_continue:
    LDR r0, =continue_msg
    BL printf

    @ Read the user's choice
    LDR r0, =fmt_int
    LDR r1, =input_var
    BL scanf

    @ Check if scanf read an integer
    CMP r0, #1
    BNE cont_scanf_fail

    @ Check trailing character for strict validation
    BL getchar
    CMP r0, #10                     @ '\n'
    BNE cont_trail_err

    @ Load the choice
    LDR r4, =input_var
    LDR r4, [r4]

    @ 1 = Yes (continue), 2 = No (quit)
    CMP r4, #1
    BEQ main_menu                   @ Loop back to main menu
    CMP r4, #2
    BEQ exit_program                @ Exit the program

    @ Invalid range - print error and re-ask
    LDR r0, =err_choice
    BL printf
    B ask_continue

@ Continue prompt error handlers
cont_scanf_fail:
    BL flush_input
    LDR r0, =err_choice
    BL printf
    B ask_continue

cont_trail_err:
    BL flush_input
    LDR r0, =err_choice
    BL printf
    B ask_continue

@ ===========================================================
@ exit_program: Prints goodbye message and returns control
@ to the operating system with exit code 0.
@ ===========================================================
exit_program:
    LDR r0, =goodbye_msg
    BL printf

    MOV r0, #0                      @ Return code 0 (success)
    POP {r4-r8, lr}                 @ Restore callee-saved registers
    BX lr                           @ Return to OS

@ ===========================================================
@                   UTILITY FUNCTIONS
@ ===========================================================

@ ===========================================================
@ get_positive_int: Prompts the user for a positive integer,
@ validates the input, and re-prompts on invalid entries.
@
@ Rejects: non-integer input (strings, characters),
@          floating-point input (e.g., "3.14"),
@          zero, and negative numbers.
@
@ Input:  r0 = address of the prompt string to display
@ Output: r0 = valid positive integer
@ ===========================================================
get_positive_int:
    PUSH {r4, lr}                   @ Save prompt addr register and LR
    MOV r4, r0                      @ r4 = saved prompt string address

@ Loop until a valid positive integer is entered
gpi_loop:
    @ Print the prompt message
    MOV r0, r4
    BL printf

    @ Attempt to read an integer with scanf
    LDR r0, =fmt_int
    LDR r1, =input_var
    BL scanf

    @ Check if scanf successfully read exactly one integer
    CMP r0, #1
    BNE gpi_scanf_fail              @ Failed: non-integer input

    @ Check trailing character to detect partial matches
    @ For example, "3.14" reads 3 but leaves ".14" in buffer
    BL getchar
    CMP r0, #10                     @ Check for newline '\n'
    BNE gpi_trail_err               @ Non-newline follows the number

    @ Load the integer value
    LDR r0, =input_var
    LDR r0, [r0]

    @ Verify the value is strictly positive (> 0)
    @ This rejects zero and negative numbers (e.g., -10, 0)
    CMP r0, #0
    BGT gpi_done                    @ Valid positive integer

    @ Value is zero or negative - show error and re-prompt
    LDR r0, =err_input
    BL printf
    B gpi_loop

@ scanf returned 0 - input was not an integer (e.g., "abc", "A")
gpi_scanf_fail:
    BL flush_input                  @ Clear invalid characters from stdin
    LDR r0, =err_input
    BL printf
    B gpi_loop                      @ Re-prompt

@ Trailing non-newline character after integer (e.g., "3.14")
gpi_trail_err:
    BL flush_input                  @ Clear remaining characters
    LDR r0, =err_input
    BL printf
    B gpi_loop                      @ Re-prompt

@ Valid input obtained - return it
gpi_done:
    POP {r4, lr}                    @ Restore registers
    BX lr                           @ Return with valid integer in r0

@ ===========================================================
@ flush_input: Clears remaining characters from stdin by
@ reading until a newline character or EOF is encountered.
@ This is used after invalid input to prevent leftover
@ characters from affecting subsequent reads.
@ ===========================================================
flush_input:
    PUSH {lr}

fi_loop:
    BL getchar                      @ Read one character from stdin
    CMP r0, #10                     @ Check for newline '\n'
    BEQ fi_done
    CMN r0, #1                      @ Check for EOF (-1)
    BEQ fi_done
    B fi_loop                       @ Keep reading until newline or EOF

fi_done:
    POP {lr}
    BX lr

@ Ensure literal pool is placed here for reachability
.ltorg

@ ===========================================================
@             AREA CALCULATION SUBROUTINES
@
@ All area subroutines follow this convention:
@   - Parameters are received via the stack (POP).
@   - The main routine pushes operands in r4, r5, r6.
@   - Subroutines pop into different registers (r10, r11, r7).
@   - Results are returned via the stack (PUSH):
@       Lower register = calculated area
@       Higher register = overflow flag (0 = OK, 1 = overflow)
@   - Overflow means the result exceeds 2^32 - 1 (max unsigned
@     32-bit integer = 4,294,967,295).
@   - 64-bit multiplication (UMULL) is used to detect overflow.
@ ===========================================================

@ ===========================================================
@ triangle_area: Calculates the area of a triangle.
@
@ Stack input:  base (from r4), height (from r5)
@ Stack output: result (into r4), overflow_flag (into r5)
@ Formula: area = (base * height) / 2
@ Uses 64-bit multiply then 64-bit right shift for division.
@ ===========================================================
triangle_area:
    POP {r10, r11}                  @ r10 = base, r11 = height
    PUSH {r8, r9}                   @ Save callee-saved work registers

    @ --- 64-bit multiply: base * height ---
    @ UMULL produces a 64-bit result in r9:r8
    UMULL r8, r9, r10, r11          @ r9:r8 = base * height

    @ --- Divide by 2 using 64-bit right shift ---
    @ Shift the 64-bit value right by 1 bit
    LSR r8, r8, #1                  @ Shift low word right by 1
    ORR r8, r8, r9, LSL #31        @ Move bit 0 of high word to bit 31
    LSR r9, r9, #1                  @ Shift high word right by 1

    @ --- Check overflow ---
    @ If the high word is non-zero after division, the result
    @ does not fit in 32 bits
    MOV r10, r8                     @ r10 = area result
    CMP r9, #0
    MOVEQ r11, #0                   @ No overflow
    MOVNE r11, #1                   @ Overflow detected

    POP {r8, r9}                    @ Restore saved work registers
    PUSH {r10, r11}                 @ Push result and overflow flag
    BX lr                           @ Return to caller

@ ===========================================================
@ rectangle_area: Calculates the area of a rectangle.
@
@ Stack input:  length (from r4), width (from r5)
@ Stack output: result (into r4), overflow_flag (into r5)
@ Formula: area = length * width
@ Uses 64-bit multiply to detect overflow.
@ ===========================================================
rectangle_area:
    POP {r10, r11}                  @ r10 = length, r11 = width
    PUSH {r8, r9}                   @ Save callee-saved work registers

    @ --- 64-bit multiply: length * width ---
    UMULL r8, r9, r10, r11          @ r9:r8 = length * width

    @ --- Check overflow ---
    @ If the high word (r9) is non-zero, the result exceeds 32 bits
    MOV r10, r8                     @ r10 = area result (low 32 bits)
    CMP r9, #0
    MOVEQ r11, #0                   @ No overflow
    MOVNE r11, #1                   @ Overflow detected

    POP {r8, r9}                    @ Restore saved work registers
    PUSH {r10, r11}                 @ Push result and overflow flag
    BX lr                           @ Return to caller

@ ===========================================================
@ trapezoid_area: Calculates the area of a trapezoid.
@
@ Stack input:  side_a (from r4), side_b (from r5),
@               height (from r6)
@ Stack output: result (into r4), overflow_flag (into r5)
@ Formula: area = (a + b) * height / 2
@
@ Implementation:
@   1. Compute sum = a + b (with carry detection)
@   2. Compute 64-bit product = sum * height
@      (accounts for possible carry from addition)
@   3. Divide 64-bit product by 2 (right shift)
@   4. Check if result fits in 32 bits
@ ===========================================================
trapezoid_area:
    POP {r7, r10, r11}             @ r7 = side_a, r10 = side_b, r11 = height
    PUSH {r8, r9}                   @ Save callee-saved work registers

    @ --- Step 1: Compute sum = a + b ---
    @ Use ADDS to detect 32-bit unsigned overflow (carry flag)
    ADDS r8, r7, r10               @ r8 = (a + b) low 32 bits, C = carry
    MOV r9, #0
    ADC r9, r9, #0                  @ r9 = carry bit (0 or 1)

    @ --- Step 2: 64-bit multiply = sum * height ---
    @ The full sum is: r9 * 2^32 + r8
    @ Product = (r9 * 2^32 + r8) * r11
    @         = r8 * r11 + r9 * r11 * 2^32
    UMULL r7, r10, r8, r11          @ r10:r7 = r8 * r11 (partial product)
    MLA r10, r9, r11, r10           @ r10 += carry * height (high word)
    @ Now r10:r7 holds the full 64-bit product of (a+b) * height

    @ --- Step 3: Divide by 2 using 64-bit right shift ---
    LSR r7, r7, #1                  @ Shift low word right by 1
    ORR r7, r7, r10, LSL #31       @ Move bit 0 of high to bit 31 of low
    LSR r10, r10, #1                @ Shift high word right by 1

    @ --- Step 4: Check overflow ---
    MOV r8, r7                      @ Save result
    CMP r10, #0                     @ High word non-zero means overflow
    MOVEQ r9, #0                    @ No overflow
    MOVNE r9, #1                    @ Overflow detected

    @ --- Prepare return values ---
    MOV r10, r8                     @ r10 = area result
    MOV r11, r9                     @ r11 = overflow flag

    POP {r8, r9}                    @ Restore saved work registers
    PUSH {r10, r11}                 @ Push result and overflow flag
    BX lr                           @ Return to caller

@ ===========================================================
@ square_area: Calculates the area of a square.
@
@ Stack input:  side (from r4)
@ Stack output: result (into r4), overflow_flag (into r5)
@ Formula: area = side * side
@ Uses 64-bit multiply to detect overflow.
@ ===========================================================
square_area:
    POP {r10}                       @ r10 = side
    PUSH {r8, r9}                   @ Save callee-saved work registers

    @ --- 64-bit multiply: side * side ---
    UMULL r8, r9, r10, r10          @ r9:r8 = side * side

    @ --- Check overflow ---
    @ If the high word (r9) is non-zero, the result exceeds 32 bits
    MOV r10, r8                     @ r10 = area result
    CMP r9, #0
    MOVEQ r11, #0                   @ No overflow
    MOVNE r11, #1                   @ Overflow detected

    POP {r8, r9}                    @ Restore saved work registers
    PUSH {r10, r11}                 @ Push result and overflow flag
    BX lr                           @ Return to caller

@ ===========================================================
@ End of program
@ ===========================================================
.end
