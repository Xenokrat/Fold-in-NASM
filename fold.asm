section .data

	no_arg_msg db 'Usage ./fold <max_length', 10, 0 ; 10 == \n, 0 == \0
	no_arg_len equ $ - no_arg_msg ; $ - current pos in assembly process
	; $ - no_arg_msg sub 2 addresses and that gives the length of string
	; equ - like eval result of `$ - no_arg_msg` and assign to label

	section .bss
	arg_int    resq 1
	input_char resb 1
	buffer  resb 1024

	section .text
	global  main
	default rel
	;       It seems that the gcc linker in macOS ??? doesn’t allow absolute addressing
	;       unless you tweak some settings.
	;       So add default rel when you are referencing labeled memory locations
	;       and always use lea to get your addresses.

main:
	cmp rdi, 2; apparently, rdi holds the number of arguments == argc
	jl  .print_usage

	;   Load the second argument (argv[1])
	mov rsi, [rsi + 8]; rsi points to argv[0], so [rsi + 8] is argv[1]

	;   Convert the string to an integer
	xor rcx, rcx
	xor rax, rax

.convert_loop:
	movzx rbx, byte [rsi]; Load the next character (zero-extend to 64 bits)
	;     The instruction movzx rbx, byte [rsi] is used to load a byte-sized value
	;     from memory into a 64-bit register, while ensuring that
	;     the rest of the register is zeroed out (i.e., the upper bits are set to zero).
	cmp   rbx, 0; Check if we readche the null-terminator
	je    .conversion_done

	;   Convert ASCII digit to integer value
	sub rbx, '0'; Convert ASCII '0' - '9' to integer 0-9
	cmp rbx, 9
	ja  .error; If character is not a digit, print error

	;    Update the accumulated integer value
	;    imul rcx, rcx, 10; Multiply current result by 10
	imul rcx, 10; This is better
	add  rcx, rbx

	inc rsi; Move to the new character (pointer size?)
	jmp .convert_loop

.conversion_done:
	;   Store the converted integer in arg_int
	mov [arg_int], rcx
	xor rdx, rdx; Clear rdx
	xor rcx, rcx; Clear rcx
	;   jmp .read_loop

.read_loop:
	;   Read a single character from stdin
	mov rax, 0; sys_read
	mov rdi, 0; from stdin (FROM WHERE READ)
	lea rsi, [rel input_char]; buffer to store the character (WHERE STORE)
	mov rdx, 1; read 1 byte (HOW MUCH READ)
	syscall
	;   If sys_read successfully reads data
	;   rax will contain the number of bytes read (e.g., 1 if one byte was read).
	;   If sys_read reaches the end of the file (EOF), rax will be 0 because no bytes were read.
	;   If there is an error, rax will contain a negative error code.

	cmp rax, 0
	je  .flush_and_exit

	;   Load the char into al (sys_read Requires a Memory Buffer)
	mov al, [rel input_char]

	;   Check if the character is a newline
	cmp al, 10
	je  .write_buffer

	;   ; Store the char in the buffer
	mov rcx, [rel arg_int]; Load the max line length
	cmp rbx, rcx; Check if the current line has reached the limit
	je  .write_buffer

	;   ; Add the char to buffer
	lea rcx, [rel buffer]
	mov [rcx + rbx], al

	;   mov [buffer + rdx], al
	inc rbx
	jmp .read_loop

.write_buffer:
	;   Write the buffer contents to stdout
	mov rax, 1; sys_write
	mov rdi, 1; stdout
	lea rsi, [rel buffer]; Buffer to write
	mov rdx, rbx; Use rdx (current line length)
	syscall

	;   Reset line length counter
	xor rbx, rbx; Reset rcx (line length counter)

	; If we encountered a newline, write it to stdout
	; cmp al, 10
	; jne .read_loop; If it's not a newline, go back to reading

	;   Write a newline to stdout
	mov rax, 1; sys_write
	mov rdi, 1; stdout
	lea rsi, [rel input_char]
	mov byte [rsi], 0x0A; Insert newline character into buffer
	mov rdx, 1; Write 1 byte (newline)
	syscall

	;   Continue reading the next line
	jmp .read_loop

.print_usage:
	;   Prints usage message
	mov rax, 1
	mov rdi, 1
	lea rsi, [no_arg_msg]; put address of the usage message
	mov rdx, no_arg_len; Length of the message
	syscall

.error:
	mov rax, 60
	mov rdi, 1
	syscall

.flush_and_exit:
	;   Flush the buffer if any remaining characters exist
	cmp rdx, 0
	je  .exit

	;   Write whats remain in buffer to stdout
	mov rax, 1
	mov rdi, 1
	lea rsi, [buffer]
	mov rbx, rdx
	syscall

	;   Write a newline
	lea rsi, [rel input_char]
	mov byte [rsi], 10
	mov rdx, 1
	syscall

.exit:
	mov rax, 60
	xor rdi, rdi
	syscall
