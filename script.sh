#!/bin/bash

: <<'notice'
 *
 * Script information:
 * Universal and advanced script for Android kernel building.
 * Indentation space is 4 and is space characters.
 *
 * SPDX-License-Identifier: GPL-3.0
 *
 * Copyright (C) Dimitar Yurukov <mscalindt@protonmail.com>
 *
notice

function variables() {

    ESSENTIAL_VARIABLES() {
        TOOLCHAIN_DIR=flasho_Ysl/build/non-oc/toolchain
        KERNEL_DIR=flasho_Ysl/build/non-oc/kernel
        KERNEL_OUTPUT_DIR=workdir
        KERNEL_DEFCONFIG=ysl-perf_defconfig
        KERNEL_ARCH=arm64
    }

    SCRIPT_VARIABLES() {
        USE_CCACHE=1
        ZIP_BUILDER=1
        RECURSIVE_KERNEL_CLONE=0
        NORMAL_COMPILATION=0
    }

    OPTIONAL_VARIABLES() {

        anykernel() {
            essential_variables() {
                AK_DIR=workdir/ak3
                KERNEL_NAME=flashokernel
            }
            remote_variables() {
                AK_REPO=https://github.com/flaahokiller/AnyKernel3
                AK_BRANCH=master
            }
            zip_filename_variables() {
                APPEND_VERSION=0
                APPEND_DEVICE=0
                APPEND_ANDROID_TARGET=0
                APPEND_DATE=0
                CUSTOM_ZIP_NAME=flasho-Kernel-ysl-V4
            }
            essential_variables
            remote_variables
            zip_filename_variables
        }

        toolchain() {
            remote_variables() {
                TOOLCHAIN_REPO=https://github.com/shivamjadon/aarch64-linux-android-4.9
                TOOLCHAIN_BRANCH=master
            }
            remote_variables
        }

        clang() {
            essential_variables() {
                CLANG_DIR=
                CLANG_BIN=
                CLANG_PREFIX=
            }
            remote_variables() {
                CLANG_REPO=
                CLANG_BRANCH=
            }
            essential_variables
            remote_variables
        }

        kernel() {
            remote_variables() {
                KERNEL_REPO=https://github.com/flaahokiller/flasho_Ysl
                KERNEL_BRANCH=MaD
            }
            options() {
                KERNEL_BUILD_USER=mohit
                KERNEL_BUILD_HOST=veronica
                KERNEL_LOCALVERSION=-3.18
            }
            remote_variables
            options
        }

        miscellaneous() {
            sync_variables() {
                # NOTE: True sync. Any local changes are discarded. All remote changes are pulled.
                SYNC_AK_DIR=0
                SYNC_TC_DIR=0
                SYNC_KERNEL_DIR=0
            }
            sync_variables
        }

        anykernel
        toolchain
        clang
        kernel
        miscellaneous
    }

    ESSENTIAL_VARIABLES
    SCRIPT_VARIABLES
    OPTIONAL_VARIABLES
}

function additional_variables() {
    red='\033[1;31m'
    green='\033[1;32m'
    white='\033[1;37m'
    darkwhite='\033[0;37m'
    cyan='\033[1;36m'
    agrsv_rm=1
    akc=nah
    tcc=nope
    cgc=no
    klc=noway
    clg=bad
    out=and
    nml=boujee
    ak_clone_depth=1
    tc_clone_depth=1
    kl_clone_depth=10
    current_date=$(date +'%Y%m%d')
    scachefile="$HOME"/.bkscache
    scachefile2="$HOME"/.bkscache2
    ak_dir="$HOME"/${AK_DIR}
    tc_dir="$HOME"/${TOOLCHAIN_DIR}
    cg_dir="$HOME"/${CLANG_DIR}
    kl_dir="$HOME"/${KERNEL_DIR}
    out_dir="$HOME"/${KERNEL_OUTPUT_DIR}
    ak_kl_img="$HOME"/${AK_DIR}/Image.gz-dtb
    out_kl_img="$HOME"/${KERNEL_OUTPUT_DIR}/arch/arm64/boot/Image.gz-dtb
    nml_kl_img="$HOME"/${KERNEL_DIR}/arch/arm64/boot/Image.gz-dtb
}

function env_checks() {

    bash_check() {
        bash_ver=${BASH_VERSION}
        bash_ver_cut=$(printf "%s" "$bash_ver" | cut -c -1)

        if [ "$bash_ver_cut" = "2" ] || [ "$bash_ver_cut" = "3" ]; then
            printf "\n%bThis script requires bash 4+%b\n\n" "$red" "$darkwhite"
            exit 1
        fi
    }

    root_check() {
        if [ $EUID = 0 ]; then
            printf "\n%bYou should not run this script as root.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi
    }

    bash_check
    root_check
}

function traps() {

    abort() {
        printf "\n\n%bThe script was forcefully aborted.%b\n\n" "$white" "$darkwhite"
        exit 130
    }

    trap abort SIGINT
}

function die_codes() {

    die_20() {
        printf "\n%bYou changed one or more variables' names.%b\n\n" "$red" "$darkwhite"
        exit 20
    }

    die_21() {
        printf "\n%bYou did not define all essential variables for the current configuration.%b\n\n" "$red" "$darkwhite"
        exit 21
    }

    die_30() {
        printf "\n%bUnexpected path issue.%b\n\n" "$red" "$darkwhite"
        exit 30
    }

    die_31() {
        printf "\n%bThe cloning of a source failed.%b\n\n" "$red" "$darkwhite"
        exit 31
    }

    die_40() {
        printf "\n%bThe kernel was not compiled correctly.%b\n\n" "$red" "$darkwhite"
        exit 40
    }
}

function configuration_checker() {

    changed_variables() {
        if [ ! -v TOOLCHAIN_DIR ] || [ ! -v KERNEL_DIR ] || \
        [ ! -v KERNEL_OUTPUT_DIR ] || [ ! -v KERNEL_DEFCONFIG ] || \
        [ ! -v KERNEL_ARCH ]; then
            die_20
        fi

        if [ ! -v USE_CCACHE ] || [ ! -v ZIP_BUILDER ] || \
        [ ! -v RECURSIVE_KERNEL_CLONE ] || [ ! -v NORMAL_COMPILATION ]; then
            die_20
        fi

        if [ ! -v AK_DIR ] || [ ! -v KERNEL_NAME ] || \
        [ ! -v AK_REPO ] || [ ! -v AK_BRANCH ] || \
        [ ! -v APPEND_VERSION ] || [ ! -v APPEND_DEVICE ] || \
        [ ! -v APPEND_ANDROID_TARGET ] || [ ! -v APPEND_DATE ] || \
        [ ! -v CUSTOM_ZIP_NAME ]; then
            die_20
        fi

        if [ ! -v TOOLCHAIN_REPO ] || [ ! -v TOOLCHAIN_BRANCH ]; then
            die_20
        fi

        if [ ! -v CLANG_DIR ] || [ ! -v CLANG_BIN ] || \
        [ ! -v CLANG_PREFIX ] || [ ! -v CLANG_REPO ] || \
        [ ! -v CLANG_BRANCH ]; then
            die_20
        fi

        if [ ! -v KERNEL_REPO ] || [ ! -v KERNEL_BRANCH ] || \
        [ ! -v KERNEL_BUILD_USER ] || [ ! -v KERNEL_BUILD_HOST ] || \
        [ ! -v KERNEL_LOCALVERSION ]; then
            die_20
        fi

        if [ ! -v SYNC_AK_DIR ] || [ ! -v SYNC_TC_DIR ] || \
        [ ! -v SYNC_KERNEL_DIR ]; then
            die_20
        fi
    }

    undefined_variables() {
        if [ -z "$TOOLCHAIN_DIR" ] || [ -z "$KERNEL_DIR" ] || \
        [ -z "$KERNEL_OUTPUT_DIR" ] || [ -z "$KERNEL_DEFCONFIG" ] || \
        [ -z "$KERNEL_ARCH" ]; then
            die_21
        fi

        if [ -n "$AK_DIR" ]; then
            if [ -z "$KERNEL_NAME" ]; then
                die_21
            fi
        fi

        if [ -n "$CLANG_DIR" ]; then
            if [ -z "$CLANG_BIN" ] || [ -z "$CLANG_PREFIX" ]; then
                die_21
            fi
        fi
    }

    missing_variables() {
        if [ ! -d "$tc_dir" ] && [ -z "$TOOLCHAIN_REPO" ] && [ -z "$TOOLCHAIN_BRANCH" ]; then
            printf "\n%bToolchain is missing, and you did not define repo and branch variables for it.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ ! -d "$kl_dir" ] && [ -z "$KERNEL_REPO" ] && [ -z "$KERNEL_BRANCH" ]; then
            printf "\n%bKernel is missing, and you did not define repo and branch variables for it.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ -n "$AK_DIR" ]; then
            if [ ! -d "$ak_dir" ] && [ -z "$AK_REPO" ] && [ -z "$AK_BRANCH" ]; then
                printf "\n%bAnyKernel is missing, and you did not define repo and branch variables for it.%b\n\n" "$red" "$darkwhite"
                exit 1
            fi
        fi

        if [ -n "$CLANG_DIR" ]; then
            if [ ! -d "$cg_dir" ] && [ -z "$CLANG_REPO" ] && [ -z "$CLANG_BRANCH" ]; then
                printf "\n%bClang is missing, and you did not define repo and branch variables for it.%b\n\n" "$red" "$darkwhite"
                exit 1
            fi
        fi
    }

    incorrect_variables() {
        if [ "$KERNEL_ARCH" != "arm64" ] && [ "$KERNEL_ARCH" != "arm" ]; then
            printf "\n%bIncorrect input for KERNEL_ARCH variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$ZIP_BUILDER" = 1 ] && [ -z "$AK_DIR" ]; then
            printf "\n%bZip builder is enabled, but AK directory is not defined...%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ -n "$CLANG_DIR" ] && [ "$NORMAL_COMPILATION" = 1 ]; then
            printf "\n%bYou cannot do normal compilation with Clang.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$SYNC_AK_DIR" = 1 ] && [ -z "$AK_DIR" ]; then
            printf "\n%bSync for AK is enabled, but AK directory is not defined...%b\n\n" "$red" "$darkwhite"
            exit 1
        fi
    }

    check_the_toggles() {
        if [ "$USE_CCACHE" != 0 ] && [ "$USE_CCACHE" != 1 ]; then
            printf "\n%bIncorrect USE_CCACHE variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$ZIP_BUILDER" != 0 ] && [ "$ZIP_BUILDER" != 1 ]; then
            printf "\n%bIncorrect ZIP_BUILDER variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$RECURSIVE_KERNEL_CLONE" != 0 ] && [ "$RECURSIVE_KERNEL_CLONE" != 1 ]; then
            printf "\n%bIncorrect RECURSIVE_KERNEL_CLONE variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$NORMAL_COMPILATION" != 0 ] && [ "$NORMAL_COMPILATION" != 1 ]; then
            printf "\n%bIncorrect NORMAL_COMPILATION variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$APPEND_DATE" != 0 ] && [ "$APPEND_DATE" != 1 ]; then
            printf "\n%bIncorrect APPEND_DATE variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$SYNC_AK_DIR" != 0 ] && [ "$SYNC_AK_DIR" != 1 ]; then
            printf "\n%bIncorrect SYNC_AK_DIR variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$SYNC_TC_DIR" != 0 ] && [ "$SYNC_TC_DIR" != 1 ]; then
            printf "\n%bIncorrect SYNC_TC_DIR variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$SYNC_KERNEL_DIR" != 0 ] && [ "$SYNC_KERNEL_DIR" != 1 ]; then
            printf "\n%bIncorrect SYNC_KERNEL_DIR variable, only 0 or 1 is allowed as input for toggles.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi
    }

    check_for_slash() {
        tcd_first_char=$(printf "%s" "$TOOLCHAIN_DIR" | cut -c -1)
        tcd_last_char=$(printf "%s" "$TOOLCHAIN_DIR" | sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | cut -c -1)
        kld_first_char=$(printf "%s" "$KERNEL_DIR" | cut -c -1)
        kld_last_char=$(printf "%s" "$KERNEL_DIR" | sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | cut -c -1)
        kldo_first_char=$(printf "%s" "$KERNEL_OUTPUT_DIR" | cut -c -1)
        kldo_last_char=$(printf "%s" "$KERNEL_OUTPUT_DIR" | sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | cut -c -1)

        if [ "$tcd_first_char" = "/" ]; then
            printf "\n%bRemove the first slash (/) in TOOLCHAIN_DIR variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        elif [ "$tcd_last_char" = "/" ]; then
            printf "\n%bRemove the last slash (/) in TOOLCHAIN_DIR variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$kld_first_char" = "/" ]; then
            printf "\n%bRemove the first slash (/) in KERNEL_DIR variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        elif [ "$kld_last_char" = "/" ]; then
            printf "\n%bRemove the last slash (/) in KERNEL_DIR variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ "$kldo_first_char" = "/" ]; then
            printf "\n%bRemove the first slash (/) in KERNEL_OUTPUT_DIR variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        elif [ "$kldo_last_char" = "/" ]; then
            printf "\n%bRemove the last slash (/) in KERNEL_OUTPUT_DIR variable.%b\n\n" "$red" "$darkwhite"
            exit 1
        fi

        if [ -n "$AK_DIR" ]; then
            akd_first_char=$(printf "%s" "$AK_DIR" | cut -c -1)
            akd_last_char=$(printf "%s" "$AK_DIR" | sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | cut -c -1)

            if [ "$akd_first_char" = "/" ]; then
                printf "\n%bRemove the first slash (/) in AK_DIR variable.%b\n\n" "$red" "$darkwhite"
                exit 1
            elif [ "$akd_last_char" = "/" ]; then
                printf "\n%bRemove the last slash (/) in AK_DIR variable.%b\n\n" "$red" "$darkwhite"
                exit 1
            fi
        fi

        if [ -n "$CLANG_DIR" ]; then
            cgd_first_char=$(printf "%s" "$CLANG_DIR" | cut -c -1)
            cgd_last_char=$(printf "%s" "$CLANG_DIR" | sed '/\n/!G;s/\(.\)\(.*\n\)/&\2\1/;//D;s/.//' | cut -c -1)

            if [ "$cgd_first_char" = "/" ]; then
                printf "\n%bRemove the first slash (/) in CLANG_DIR variable.%b\n\n" "$red" "$darkwhite"
                exit 1
            elif [ "$cgd_last_char" = "/" ]; then
                printf "\n%bRemove the last slash (/) in CLANG_DIR variable.%b\n\n" "$red" "$darkwhite"
                exit 1
            fi
        fi
    }

    changed_variables
    undefined_variables
    missing_variables
    incorrect_variables
    check_the_toggles
    check_for_slash
}

function package_checker() {

    ccache_binary() {
        if [ "$USE_CCACHE" = 1 ]; then
            if ! command -v ccache > /dev/null 2>&1; then
                printf "\n%bccache not found.%b\n\n" "$red" "$darkwhite"

                if command -v sudo > /dev/null 2>&1; then
                    if command -v apt > /dev/null 2>&1; then
                        printf "%bTIP: sudo apt install ccache%b\n\n" "$white" "$darkwhite"
                    elif command -v pacman > /dev/null 2>&1; then
                        printf "%bTIP: sudo pacman -S ccache%b\n\n" "$white" "$darkwhite"
                    elif command -v dnf > /dev/null 2>&1; then
                        printf "%bTIP: sudo dnf install ccache%b\n\n" "$white" "$darkwhite"
                    elif command -v zypper > /dev/null 2>&1; then
                        printf "%bTIP: sudo zypper install ccache%b\n\n" "$white" "$darkwhite"
                    elif command -v emerge > /dev/null 2>&1; then
                        printf "%bTIP: sudo emerge -a ccache%b\n\n" "$white" "$darkwhite"
                    fi
                else
                    if command -v apt > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'apt install ccache'%b\n\n" "$white" "$darkwhite"
                    elif command -v pacman > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'pacman -S ccache'%b\n\n" "$white" "$darkwhite"
                    elif command -v dnf > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'dnf install ccache'%b\n\n" "$white" "$darkwhite"
                    elif command -v zypper > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'zypper install ccache'%b\n\n" "$white" "$darkwhite"
                    elif command -v emerge > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'emerge -a ccache'%b\n\n" "$white" "$darkwhite"
                    fi
                fi

                exit 1
            fi
        fi
    }

    git_binary() {
        if [ -n "$AK_REPO" ] || [ -n "$AK_BRANCH" ] || \
        [ -n "$TOOLCHAIN_REPO" ] || [ -n "$TOOLCHAIN_BRANCH" ] || \
        [ -n "$CLANG_REPO" ] || [ -n "$CLANG_BRANCH" ] || \
        [ -n "$KERNEL_REPO" ] || [ -n "$KERNEL_BRANCH" ] || \
        [ "$SYNC_AK_DIR" = 1 ] || [ "$SYNC_TC_DIR" = 1 ] || \
        [ "$SYNC_KERNEL_DIR" = 1 ]; then
            if ! command -v git > /dev/null 2>&1; then
                printf "\n%bgit not found.%b\n\n" "$red" "$darkwhite"

                if command -v sudo > /dev/null 2>&1; then
                    if command -v apt > /dev/null 2>&1; then
                        printf "%bTIP: sudo apt install git%b\n\n" "$white" "$darkwhite"
                    elif command -v pacman > /dev/null 2>&1; then
                        printf "%bTIP: sudo pacman -S git%b\n\n" "$white" "$darkwhite"
                    elif command -v dnf > /dev/null 2>&1; then
                        printf "%bTIP: sudo dnf install git%b\n\n" "$white" "$darkwhite"
                    elif command -v zypper > /dev/null 2>&1; then
                        printf "%bTIP: sudo zypper install git%b\n\n" "$white" "$darkwhite"
                    elif command -v emerge > /dev/null 2>&1; then
                        printf "%bTIP: sudo emerge -a git%b\n\n" "$white" "$darkwhite"
                    fi
                else
                    if command -v apt > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'apt install git'%b\n\n" "$white" "$darkwhite"
                    elif command -v pacman > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'pacman -S git'%b\n\n" "$white" "$darkwhite"
                    elif command -v dnf > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'dnf install git'%b\n\n" "$white" "$darkwhite"
                    elif command -v zypper > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'zypper install git'%b\n\n" "$white" "$darkwhite"
                    elif command -v emerge > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'emerge -a git'%b\n\n" "$white" "$darkwhite"
                    fi
                fi

                exit 1
            fi
        fi
    }

    zip_binary() {
        if [ "$ZIP_BUILDER" = 1 ]; then
            if ! command -v zip > /dev/null 2>&1; then
                printf "\n%bzip not found.%b\n\n" "$red" "$darkwhite"

                if command -v sudo > /dev/null 2>&1; then
                    if command -v apt > /dev/null 2>&1; then
                        printf "%bTIP: sudo apt install zip%b\n\n" "$white" "$darkwhite"
                    elif command -v pacman > /dev/null 2>&1; then
                        printf "%bTIP: sudo pacman -S zip%b\n\n" "$white" "$darkwhite"
                    elif command -v dnf > /dev/null 2>&1; then
                        printf "%bTIP: sudo dnf install zip%b\n\n" "$white" "$darkwhite"
                    elif command -v zypper > /dev/null 2>&1; then
                        printf "%bTIP: sudo zypper install zip%b\n\n" "$white" "$darkwhite"
                    elif command -v emerge > /dev/null 2>&1; then
                        printf "%bTIP: sudo emerge -a zip%b\n\n" "$white" "$darkwhite"
                    fi
                else
                    if command -v apt > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'apt install zip'%b\n\n" "$white" "$darkwhite"
                    elif command -v pacman > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'pacman -S zip'%b\n\n" "$white" "$darkwhite"
                    elif command -v dnf > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'dnf install zip'%b\n\n" "$white" "$darkwhite"
                    elif command -v zypper > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'zypper install zip'%b\n\n" "$white" "$darkwhite"
                    elif command -v emerge > /dev/null 2>&1; then
                        printf "%bTIP: su root -c 'emerge -a zip'%b\n\n" "$white" "$darkwhite"
                    fi
                fi

                exit 1
            fi
        fi
    }

    ccache_binary
    git_binary
    zip_binary
}

function cloning() {

    anykernel() {
        if [ -n "$AK_DIR" ]; then
            if [ ! -d "$ak_dir" ]; then
                akc=y
                printf "\n%bStarting clone of AK with depth %d...%b\n" "$white" "$ak_clone_depth" "$darkwhite"
                git clone --branch "${AK_BRANCH}" --depth "${ak_clone_depth}" "${AK_REPO}" "${ak_dir}"
            fi
        fi
    }

    toolchain() {
        if [ ! -d "$tc_dir" ]; then
            tcc=y
            printf "\n%bStarting clone of the toolchain with depth %d...%b\n" "$white" "$tc_clone_depth" "$darkwhite"
            git clone --branch "${TOOLCHAIN_BRANCH}" --depth "${tc_clone_depth}" "${TOOLCHAIN_REPO}" "${tc_dir}"
        fi
    }

    clang() {
        if [ -n "$CLANG_DIR" ]; then
            if [ ! -d "$cg_dir" ]; then
                cgc=y
                printf "\n%bStarting clone of Clang with depth %d...%b\n" "$white" "$tc_clone_depth" "$darkwhite"
                git clone --branch "${CLANG_BRANCH}" --depth "${tc_clone_depth}" "${CLANG_REPO}" "${cg_dir}"
            fi
        fi
    }

    kernel() {
        if [ ! -d "$kl_dir" ]; then
            klc=y
            printf "\n%bStarting clone of the kernel with depth %d...%b\n" "$white" "$kl_clone_depth" "$darkwhite"
            if [ "$RECURSIVE_KERNEL_CLONE" = 1 ]; then
                git clone --recursive --branch "${KERNEL_BRANCH}" --depth "${kl_clone_depth}" "${KERNEL_REPO}" "${kl_dir}"
            else
                git clone --branch "${KERNEL_BRANCH}" --depth "${kl_clone_depth}" "${KERNEL_REPO}" "${kl_dir}"
            fi
        fi
    }

    check_directories() {
        if [ -n "$AK_DIR" ]; then
            if [ ! -d "$ak_dir" ]; then
                die_31
            fi
        fi

        if [ ! -d "$tc_dir" ]; then
            die_31
        fi

        if [ -n "$CLANG_DIR" ]; then
            if [ ! -d "$cg_dir" ]; then
                die_31
            fi
        fi

        if [ ! -d "$kl_dir" ]; then
            die_31
        fi
    }

    sync_directories() {
        if [ "$SYNC_AK_DIR" = 1 ]; then
            if [ "$akc" != y ]; then
                printf "\n%bStarting sync of AK source...%b\n" "$white" "$darkwhite"
                cd "${ak_dir}" || die_30
                git reset --hard "@{upstream}"
                git clean -fd
                git pull --rebase=preserve
            fi
        fi

        if [ "$SYNC_TC_DIR" = 1 ]; then
            if [ "$tcc" != y ]; then
                printf "\n%bStarting sync of the toolchain source...%b\n" "$white" "$darkwhite"
                cd "${tc_dir}" || die_30
                git reset --hard "@{upstream}"
                git clean -fd
                git pull --rebase=preserve
            fi

            if [ -n "$CLANG_DIR" ]; then
                if [ "$cgc" != y ]; then
                    printf "\n%bStarting sync of Clang source...%b\n" "$white" "$darkwhite"
                    cd "${cg_dir}" || die_30
                    git reset --hard "@{upstream}"
                    git clean -fd
                    git pull --rebase=preserve
                fi
            fi
        fi

        if [ "$SYNC_KERNEL_DIR" = 1 ]; then
            if [ "$klc" != y ]; then
                printf "\n%bStarting sync of the kernel source...%b\n" "$white" "$darkwhite"
                cd "${kl_dir}" || die_30
                git reset --hard "@{upstream}"
                git clean -fd
                git pull --rebase=preserve
            fi
        fi
    }

    anykernel
    toolchain
    clang
    kernel
    check_directories
    sync_directories
}

function choices() {

    compilation_method() {
        if [ -n "$CLANG_DIR" ]; then
            clg=1
            printf "\n%bClang detected, starting compilation.%b\n\n" "$white" "$darkwhite"
        elif [ "$NORMAL_COMPILATION" = 0 ]; then
            out=1
            printf "\n%bStarting output folder compilation.%b\n\n" "$white" "$darkwhite"
        else
            nml=1
            printf "\n%bStarting normal compilation.%b\n\n" "$white" "$darkwhite"
        fi
    }

    compilation_method
}

function automatic_configuration() {

    set_subarch() {
        if [ "$KERNEL_ARCH" = "arm64" ]; then
            kernel_subarch=arm64
        else
            kernel_subarch=arm
        fi
    }

    get_toolchain_prefix() {
        cd "${tc_dir}"/lib/gcc || die_30
        cd -- * || die_30
        tc_prefix=$(basename "$PWD")-
    }

    ccache_path() {
        if [ "$USE_CCACHE" = 1 ]; then
            ccache_loc=$(command -v ccache)
        fi
    }

    user() {
        if [ -z "$KERNEL_BUILD_USER" ]; then
            idkme=$(id -un)
        fi
    }

    host() {
        if [ -z "$KERNEL_BUILD_HOST" ]; then
            idkmy=$(uname -n)
        fi
    }

    set_subarch
    get_toolchain_prefix
    ccache_path
    user
    host
}

function time_log_start1() {
    start1=$(date +'%s')
}

function compilation() {

    clang() {
        if [ "$clg" = 1 ]; then
            cd "${kl_dir}" || die_30

            if [ -n "$KERNEL_BUILD_USER" ]; then
                export KBUILD_BUILD_USER=${KERNEL_BUILD_USER}
            else
                export KBUILD_BUILD_USER=${idkme}
            fi

            if [ -n "$KERNEL_BUILD_HOST" ]; then
                export KBUILD_BUILD_HOST=${KERNEL_BUILD_HOST}
            else
                export KBUILD_BUILD_HOST=${idkmy}
            fi

            if [ -n "$KERNEL_LOCALVERSION" ]; then
                export LOCALVERSION=${KERNEL_LOCALVERSION}
            fi

            export ARCH=${KERNEL_ARCH}
            export SUBARCH=${kernel_subarch}

            make O="${out_dir}" \
                ARCH="${KERNEL_ARCH}" \
                "${KERNEL_DEFCONFIG}"

            if [ "$USE_CCACHE" = 1 ]; then
                cpaths="${ccache_loc} ${cg_dir}/bin:${tc_dir}/bin:${PATH}"
            else
                cpaths="${cg_dir}/bin:${tc_dir}/bin:${PATH}"
            fi

            tc_paths=${cpaths} \
            make O="${out_dir}" \
                ARCH="${KERNEL_ARCH}" \
                CC="${CLANG_BIN}" \
                CLANG_TRIPLE="${CLANG_PREFIX}" \
                CROSS_COMPILE="${tc_prefix}" \
                -j"$(nproc --all)"

            makeexit1=$(printf "%d" "$?")
        fi
    }

    output_folder() {
        if [ "$out" = 1 ]; then
            cd "${kl_dir}" || die_30

            if [ -n "$KERNEL_BUILD_USER" ]; then
                export KBUILD_BUILD_USER=${KERNEL_BUILD_USER}
            else
                export KBUILD_BUILD_USER=${idkme}
            fi

            if [ -n "$KERNEL_BUILD_HOST" ]; then
                export KBUILD_BUILD_HOST=${KERNEL_BUILD_HOST}
            else
                export KBUILD_BUILD_HOST=${idkmy}
            fi

            if [ -n "$KERNEL_LOCALVERSION" ]; then
                export LOCALVERSION=${KERNEL_LOCALVERSION}
            fi

            export ARCH=${KERNEL_ARCH}
            export SUBARCH=${kernel_subarch}

            if [ "$USE_CCACHE" = 1 ]; then
                export CROSS_COMPILE="${ccache_loc} ${tc_dir}/bin/${tc_prefix}"
            else
                export CROSS_COMPILE="${tc_dir}/bin/${tc_prefix}"
            fi

            make O="${out_dir}" \
                ARCH="${KERNEL_ARCH}" \
                "${KERNEL_DEFCONFIG}"

            make O="${out_dir}" \
                ARCH="${KERNEL_ARCH}" \
                -j"$(nproc --all)"

            makeexit2=$(printf "%d" "$?")
        fi
    }

    normal() {
        if [ "$nml" = 1 ]; then
            cd "${kl_dir}" || die_30

            if [ -n "$KERNEL_BUILD_USER" ]; then
                export KBUILD_BUILD_USER=${KERNEL_BUILD_USER}
            else
                export KBUILD_BUILD_USER=${idkme}
            fi

            if [ -n "$KERNEL_BUILD_HOST" ]; then
                export KBUILD_BUILD_HOST=${KERNEL_BUILD_HOST}
            else
                export KBUILD_BUILD_HOST=${idkmy}
            fi

            if [ -n "$KERNEL_LOCALVERSION" ]; then
                export LOCALVERSION=${KERNEL_LOCALVERSION}
            fi

            export ARCH=${KERNEL_ARCH}
            export SUBARCH=${kernel_subarch}

            if [ "$USE_CCACHE" = 1 ]; then
                CROSS_COMPILE="${ccache_loc} ${tc_dir}/bin/${tc_prefix}"
            else
                CROSS_COMPILE="${tc_dir}/bin/${tc_prefix}"
            fi

            make "${KERNEL_DEFCONFIG}"

            CROSS_COMPILE=${CROSS_COMPILE} make -j"$(nproc --all)"

            makeexit3=$(printf "%d" "$?")
        fi
    }

    clang
    output_folder
    normal
}

function time_log_end1() {
    end1=$(date +'%s')
    comptime=$((end1-start1))
}

function compilation_report() {
    if [ "$clg" = 1 ]; then
        if [ "$makeexit1" != 0 ]; then
            die_40
        fi
    elif [ "$out" = 1 ]; then
        if [ "$makeexit2" != 0 ]; then
            die_40
        fi
    elif [ "$nml" = 1 ]; then
        if [ "$makeexit3" != 0 ]; then
            die_40
        fi
    fi

    if [ "$clg" = 1 ] || [ "$out" = 1 ]; then
        if [ -f "$out_kl_img" ]; then
            printf "\n%bThe kernel is compiled successfully!%b\n\n" "$green" "$darkwhite"
        else
            die_40
        fi
    elif [ "$nml" = 1 ]; then
        if [ -f "$nml_kl_img" ]; then
            printf "\n%bThe kernel is compiled successfully!%b\n\n" "$green" "$darkwhite"
        else
            die_40
        fi
    fi
}

function stats() {

    convert_bytes_func() {
        b=${1:-0}; d=''; s=0; S=(Bytes {K,M,G,T,P,E,Z,Y}B)
        while ((b > 1000)); do
            d="$(printf ".%02d" $((b % 1000 * 100 / 1000)))"
            b=$((b / 1000))
            (( s++ ))
        done
        echo "$b$d ${S[$s]}"
    }

    get_size_of_image_in_bytes() {
        if [ "$out" = 1 ]; then
            bytesoutimg=$(wc -c < "${out_kl_img}")
        else
            bytesnmlimg=$(wc -c < "${nml_kl_img}")
        fi
    }

    convert_bytes_of_image() {
        if [ "$out" = 1 ]; then
            sizeoutimg=$(convert_bytes_func "${bytesoutimg}")
        else
            sizenmlimg=$(convert_bytes_func "${bytesnmlimg}")
        fi
    }

    kernel_stats() {
        printf "%b> Defconfig: %s%b\n" "$white" "$KERNEL_DEFCONFIG" "$darkwhite"

        if [ -n "$KERNEL_LOCALVERSION" ]; then
            printf "%b> Localversion: %s%b\n" "$white" "$KERNEL_LOCALVERSION" "$darkwhite"
        fi

        if [ -n "$KERNEL_BUILD_USER" ]; then
            printf "%b> User: %s%b\n" "$white" "$KERNEL_BUILD_USER" "$darkwhite"
        else
            printf "%b> User: %s%b\n" "$white" "$idkme" "$darkwhite"
        fi

        if [ -n "$KERNEL_BUILD_HOST" ]; then
            printf "%b> Host: %s%b\n" "$white" "$KERNEL_BUILD_HOST" "$darkwhite"
        else
            printf "%b> Host: %s%b\n" "$white" "$idkmy" "$darkwhite"
        fi
    }

    compilation_stats() {
        comptimemin=$((comptime / 60))
        comptimesec=$((comptime % 60))

        if [ "$comptimemin" = 1 ] && [ "$comptimesec" = 1 ]; then
            printf "%b> Compilation took: %d minute and %d second%b\n" "$white" "$comptimemin" "$comptimesec" "$darkwhite"
        elif [ "$comptimemin" = 1 ] && [ "$comptimesec" != 1 ]; then
            printf "%b> Compilation took: %d minute and %d seconds%b\n" "$white" "$comptimemin" "$comptimesec" "$darkwhite"
        elif [ "$comptimemin" != 1 ] && [ "$comptimesec" = 1 ]; then
            printf "%b> Compilation took: %d minutes and %d second%b\n" "$white" "$comptimemin" "$comptimesec" "$darkwhite"
        elif [ "$comptimemin" != 1 ] && [ "$comptimesec" != 1 ]; then
            printf "%b> Compilation took: %d minutes and %d seconds%b\n" "$white" "$comptimemin" "$comptimesec" "$darkwhite"
        fi

        if [ "$clg" = 1 ]; then
            if [ "$USE_CCACHE" = 1 ]; then
                printf "%b> Compilation details: out-%s-ccache%b\n" "$white" "$CLANG_BIN" "$darkwhite"
            else
                printf "%b> Compilation details: out-%s%b\n" "$white" "$CLANG_BIN" "$darkwhite"
            fi
        elif [ "$out" = 1 ]; then
            if [ "$USE_CCACHE" = 1 ]; then
                printf "%b> Compilation details: out-gcc-ccache%b\n" "$white" "$darkwhite"
            else
                printf "%b> Compilation details: out-gcc%b\n" "$white" "$darkwhite"
            fi
        elif [ "$nml" = 1 ]; then
            if [ "$USE_CCACHE" = 1 ]; then
                printf "%b> Compilation details: normal-gcc-ccache%b\n" "$white" "$darkwhite"
            else
                printf "%b> Compilation details: normal-gcc%b\n" "$white" "$darkwhite"
            fi
        fi
    }

    image_stats() {

        read_stored_image_size() {
            if [ -f "$scachefile" ]; then
                grep -Fq "directory=$kl_dir" "$scachefile"
                grepexit=$(printf "%d" "$?")

                if [ "$grepexit" = 1 ]; then
                    rm -f "${scachefile}"
                fi
            fi

            if [ -f "$scachefile" ]; then
                if [ "$out" = 1 ]; then
                    if grep -Fq "out.kernel.image.size" "${scachefile}"; then
                        sizestoredoutimg=$(grep out.kernel.image.size "${scachefile}" | cut -d "=" -f2)
                    fi
                else
                    if grep -Fq "nml.kernel.image.size" "${scachefile}"; then
                        sizestorednmlimg=$(grep nml.kernel.image.size "${scachefile}" | cut -d "=" -f2)
                    fi
                fi
            fi
        }

        output_image_stats() {
            if [ -f "$scachefile" ]; then
                if [ "$out" = 1 ]; then
                    if grep -Fq out.kernel.image.size "${scachefile}"; then
                        printf "%b> Image size: %s (PREVIOUSLY: %s)%b\n" "$white" "$sizeoutimg" "$sizestoredoutimg" "$darkwhite"
                    fi
                else
                    if grep -Fq nml.kernel.image.size "${scachefile}"; then
                        printf "%b> Image size: %s (PREVIOUSLY: %s)%b\n" "$white" "$sizenmlimg" "$sizestorednmlimg" "$darkwhite"
                    fi
                fi
            else
                if [ "$out" = 1 ]; then
                    printf "%b> Image size: %s%b\n" "$white" "$sizeoutimg" "$darkwhite"
                else
                    printf "%b> Image size: %s%b\n" "$white" "$sizenmlimg" "$darkwhite"
                fi
            fi

            if [ "$out" = 1 ]; then
                printf "%b> Image location: %s%b\n\n" "$white" "$out_kl_img" "$darkwhite"
            else
                printf "%b> Image location: %s%b\n\n" "$white" "$nml_kl_img" "$darkwhite"
            fi
        }

        store_image_size() {
            rm -f "${scachefile}"
            touch "${scachefile}"

            printf "directory=%s\n" "$kl_dir" >> "${scachefile}"

            if [ "$out" = 1 ]; then
                printf "out.kernel.image.size=%s\n" "$sizeoutimg" >> "${scachefile}"
            else
                printf "nml.kernel.image.size=%s\n" "$sizenmlimg" >> "${scachefile}"
            fi
        }

        read_stored_image_size
        output_image_stats
        store_image_size
    }

    get_size_of_image_in_bytes
    convert_bytes_of_image
    kernel_stats
    compilation_stats
    image_stats
}

function zip_builder() {

    copy_image() {
        if [ "$clg" = 1 ] || [ "$out" = 1 ]; then
            cp "${out_kl_img}" "${ak_kl_img}"
        elif [ "$nml" = 1 ]; then
            cp "${nml_kl_img}" "${ak_kl_img}"
        fi
    }

    remove_old_zip() {
        rm -f "${ak_dir}"/"${KERNEL_NAME}"*.zip

        aggressive_removal() {
            if [ "$agrsv_rm" = 1 ]; then
                ls "${ak_dir}"/*.zip > /dev/null 2>&1
                lsexit=$(printf "%d" "$?")

                if [ "$lsexit" = 0 ]; then
                    rm -rf "${ak_dir}"/*.zip
                fi
            fi
        }

        aggressive_removal
    }

    filename() {
        if [ -n "$CUSTOM_ZIP_NAME" ]; then
            filename="${CUSTOM_ZIP_NAME}.zip"
        else
            filename="${KERNEL_NAME}"

            if [ -n "$APPEND_VERSION" ]; then
                filename="${filename}-${APPEND_VERSION}"
            fi

            if [ -n "$APPEND_DEVICE" ]; then
                filename="${filename}-${APPEND_DEVICE}"
            fi

            if [ -n "$APPEND_ANDROID_TARGET" ]; then
                filename="${filename}-${APPEND_ANDROID_TARGET}"
            fi

            if [ "$APPEND_DATE" = 1 ]; then
                filename="${filename}-${current_date}"
            fi

            filename="${filename}.zip"
        fi
    }

    create_zip() {
        printf "%bPacking the kernel...%b\n\n" "$cyan" "$darkwhite"

        cd "${ak_dir}" || die_30
        zip -qFSr9 "${filename}" ./* -x .git ./*.zip README.md
    }

    get_size_of_zip_in_bytes() {
        byteszip=$(wc -c < "${ak_dir}"/"${filename}")
    }

    convert_bytes_of_zip() {
        sizezip=$(convert_bytes_func "${byteszip}")
    }

    zip_stats() {

        read_stored_zip_size() {
            if [ -f "$scachefile2" ]; then
                grep -Fq "directory=$kl_dir" "$scachefile2"
                grepexit2=$(printf "%d" "$?")

                if [ "$grepexit2" = 1 ]; then
                    rm -f "${scachefile2}"
                fi
            fi

            if [ -f "$scachefile2" ]; then
                if grep -Fq "kernel.zip.size" "${scachefile2}"; then
                    sizestoredzip=$(grep kernel.zip.size "${scachefile2}" | cut -d "=" -f2)
                fi
            fi
        }

        output_zip_stats() {
            if [ -f "$scachefile2" ]; then
                if grep -Fq kernel.zip.size "${scachefile2}"; then
                    printf "%b> Zip size: %s (PREVIOUSLY: %s)%b\n" "$white" "$sizezip" "$sizestoredzip" "$darkwhite"
                fi
            else
                printf "%b> Zip size: %s%b\n" "$white" "$sizezip" "$darkwhite"
            fi

            printf "%b> Zip location: %s/%s%b\n\n" "$white" "$ak_dir" "$filename" "$darkwhite"
        }

        store_zip_size() {
            rm -f "${scachefile2}"
            touch "${scachefile2}"

            printf "directory=%s\n" "$kl_dir" >> "${scachefile2}"
            printf "kernel.zip.size=%s\n" "$sizezip" >> "${scachefile2}"
        }

        read_stored_zip_size
        output_zip_stats
        store_zip_size
    }

    copy_image
    remove_old_zip
    filename
    create_zip
    get_size_of_zip_in_bytes
    convert_bytes_of_zip
    zip_stats
}

variables
additional_variables
env_checks
traps
die_codes
configuration_checker
package_checker
cloning
choices
automatic_configuration
time_log_start1
compilation
time_log_end1
compilation_report
stats

if [ "$ZIP_BUILDER" = 1 ]; then
    zip_builder
fi
