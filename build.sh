#!/bin/bash

MICRO_FLAG=-DSTM32F446xx
STM32CUBEF4_FOLDER="STM32CubeF4"
STM32CUBEF4_TAG="v1.28.1"
STM32CUBEF4_REPO="https://github.com/STMicroelectronics/$STM32CUBEF4_FOLDER"

OBJ_FOLDER="obj"
ASM_LIST_FOLDER="list"

OBJ_DUMP="arm-none-eabi-objdump"
COMPILER_C="arm-none-eabi-gcc"
COMPILER_CPP="arm-none-eabi-g++"
LINKER="arm-none-eabi-g++"
LINKER="arm-none-eabi-g++"
CFLAGS="-O2 -mthumb --specs=nano.specs -march=armv7e-m -MMD -MP"
CPPFLAGS="-std=c++23 --no-rtti -O2 -mthumb --specs=nano.specs -march=armv7e-m -MMD -MP"
ASM_FLAGS="-mcpu=cortex-m4 -c -x assembler-with-cpp -MMD -MP --specs=nano.specs -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb"

LDFLAGS="-T $STM32CUBEF4_FOLDER/Projects/STM32446E-Nucleo/Examples/GPIO/GPIO_IOToggle/SW4STM32/STM32F4xx-Nucleo/STM32F446RETx_FLASH.ld -march=armv7e-m   -Wl,-Map="main.map" -Wl,--gc-sections -static     -Wl,--start-group  -Wl,--end-group" # Asumo que todavía necesitas esta bandera
# -lc -lm

BUILD_DIR="build"
mkdir -p $BUILD_DIR
mkdir -p $BUILD_DIR/$OBJ_FOLDER
mkdir -p $BUILD_DIR/$ASM_LIST_FOLDER


# DOWNLOAD STM32CUBE MX
if [ ! -d "$STM32CUBEF4_FOLDER" ]; then
    echo "$STM32CUBEF4_FOLDER does not exist. Cloning from $STM32CUBEF4_REPO..."
    git clone --depth 1 --branch $STM32CUBEF4_TAG $STM32CUBEF4_REPO
fi

INCLUDES="-I./$STM32CUBEF4_FOLDER/Drivers/CMSIS/Device/ST/STM32F4xx/Include -I./$STM32CUBEF4_FOLDER/Drivers/CMSIS/Core/Include"

CPP_FILES=(
    main.cpp
    # functions.cpp
)

C_FILES=(
    $STM32CUBEF4_FOLDER/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/system_stm32f4xx.c
    $STM32CUBEF4_FOLDER/Projects/STM324xG_EVAL/Examples/BSP/SW4STM32/syscalls.c
)

ASM_FILES=(
    $STM32CUBEF4_FOLDER/Drivers/CMSIS/Device/ST/STM32F4xx/Source/Templates/gcc/startup_stm32f407xx.s
) 

OBJ_FILES=()
# set -x

for src in "${CPP_FILES[@]}"; do
    obj="${BUILD_DIR}/$OBJ_FOLDER/$(basename ${src%.*}_cpp.o)"
    $COMPILER_CPP   -c "$src"  $MICRO_FLAG $CPPFLAGS $INCLUDES -o "$obj"
    OBJ_FILES+=("$obj")
done

for src in "${C_FILES[@]}"; do
    obj="${BUILD_DIR}/$OBJ_FOLDER/$(basename ${src%.*}_c.o)"
    $COMPILER_C   -c "$src"  $MICRO_FLAG $CFLAGS $INCLUDES -o "$obj"
    OBJ_FILES+=("$obj")
done

# Compilación de archivos ensamblador
for src in "${ASM_FILES[@]}"; do
    obj="${BUILD_DIR}/$OBJ_FOLDER/$(basename ${src%.*}_asm.o)"
    $COMPILER_C $ASM_FLAGS  $MICRO_FLAG $INCLUDES  -o "$obj" "$src"
    OBJ_FILES+=("$obj")
done

echo "------"
echo "Archivos C: ${C_FILES[@]}"
echo "Archivos CPP: ${CPP_FILES[@]}"
echo "Archivos O: ${OBJ_FILES[@]}"
echo "------"

$LINKER  "${OBJ_FILES[@]}"  $LDFLAGS  -o test.elf

for obj_file in "$BUILD_DIR/$OBJ_FOLDER"/*.o; do
    base_name=$(basename -- "$obj_file")
    base_name_without_extension="${base_name%.*}"
    lst_file="$BUILD_DIR/$ASM_LIST_FOLDER/${base_name_without_extension}.lst"
    
    $OBJ_DUMP -S --demangle "$obj_file" > "$lst_file"
done
