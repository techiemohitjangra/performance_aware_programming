#include <fcntl.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

enum instruction_type {
    mov = 34,
};

union instruction {
    uint16_t value;
    struct __attribute__((packed)) {
        bool w : 1;
        bool d : 1;
        uint8_t op_code : 6;
        uint8_t r_m : 3;
        uint8_t reg : 3;
        uint8_t mod : 2;
    };
};

enum registers {
    al = 0,
    ax,
    cl,
    cx,
    dl,
    dx,
    bl,
    bx,
    ah,
    sp,
    ch,
    bp,
    dh,
    si,
    bh,
    di,
};

typedef union instruction instruction;
typedef enum registers registers;
typedef enum instruction_type instruction_type;

char *register_name(registers reg) {
    switch (reg) {
    case al:
        return "al";
    case ax:
        return "ax";
    case cl:
        return "cl";
    case cx:
        return "cx";
    case dl:
        return "dl";
    case dx:
        return "dx";
    case bl:
        return "bl";
    case bx:
        return "bx";
    case ah:
        return "ah";
    case sp:
        return "sp";
    case ch:
        return "ch";
    case bp:
        return "bp";
    case dh:
        return "dh";
    case si:
        return "si";
    case bh:
        return "bh";
    case di:
        return "di";
    }
}

char *instruction_name(instruction_type instr) {
    switch (instr) {
    case mov:
        return "mov";
    }
}

void disassemble(instruction instr) {
    registers destination;
    registers source;
    if (instr.d == 0) {
        destination = (instr.r_m << 1) + instr.w;
        source = (instr.reg << 1) + instr.w;
    } else {
        destination = (instr.reg << 1) + instr.w;
        source = (instr.r_m << 1) + instr.w;
    }
    printf("%s %s, %s\n", instruction_name((instruction_type)instr.op_code),
           register_name(destination), register_name(source));
}

int main(int argc, char **argv) {
    if (argc == 2) {
        char *filename = argv[1];
        int fd = open(filename, O_RDONLY);
        if (fd < 0) {
            perror("Failed to open file");
            return EXIT_FAILURE;
        }
        struct stat file_stats;
        if (fstat(fd, &file_stats) < 0) {
            perror("failed to get file size");
            return EXIT_FAILURE;
        }

        size_t file_size = file_stats.st_size;
        unsigned char *data =
            mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, fd, 0);
        if (data == MAP_FAILED) {
            perror("mmap failed");
            close(fd);
            return EXIT_FAILURE;
        }
        int instruction_count = (float)file_size / sizeof(instruction);
        int idx = 0;
        instruction *instructions = (instruction *)data;
        while (idx < instruction_count) {
            disassemble(instructions[idx]);
            idx += 1;
        }
        close(fd);
    } else {
        printf("Usage: %s <input_file>\n", argv[0]);
    }
    return EXIT_SUCCESS;
}
