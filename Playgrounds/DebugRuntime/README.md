#  A playground project for exploring swift runtime and stdlib libraries

This Xcode project helps explore the inner workings of Swift runtime and standard libraries.

## Installation

### Directory setup

This project expects to be located next to the `SwiftProject` directory, which should contain all swift sources and build directory:
```
SOME_DIR
    |- SwiftProject
    |    |- build
    |    |- ...
    |    |- llvm-project
    |    |- ninja
    |    |- sourcekit-lsp
    |    |- swift
    |    |- swift-corelibs-foundation
    |    |- ...
    |
    |- [TODO]
```

If you already have Swift project cloned and built on your machine, you can skip the first step, but you'll need to tweak a couple of settings; see below. 

### Clone and Build Swift project

1. Clone the main project: `git clone git@github.com:apple/swift.git`
2. Clone other required repositories: `./swift/utils/update-checkout --clone --clean --scheme swift/master`. This will set things up to build the `master` branch. Alternatively, use another branch, for example: `./swift/utils/update-checkout --clone --scheme swift/swift-5.1-branch`. As of this writing, repeatedly switching to between schemes requires `rm -rf llvm-project`, due to some error in `./swift/utils/update-checkout`. Additionally, the required symlinks are not being created, and need to be created manually: `ln -s ./llvm-project/clang/; ln -s ./llvm-project/clang-tools-extra/; ln -s ./llvm-project/compiler-rt; ln -s ./llvm-project/libcxx; ln -s ./llvm-project/lldb; ln -s ./llvm-project/llvm`.
3. Build: `./swift/utils/build-script -d --debug-swift-stdlib --skip-build-benchmarks -x`. It will take some time...
4. Change back to your projects directory: `cd ..`

### Clone This Project
1. `TODO`

### Update Paths

(This is only necessary if Swift was not cloned and built using instructions above)

1. Choose `Edit Scheme` from the Scheme menu
2. Update the `DYLD_LIBRARY_PATH` to point to the location of Swift `build/Xcode-DebugAssert/swift-macosx-x86_64/Debug/lib/swift/macosx` directory
3. Click on `Swift` source folder, and show its File Inspector (`⌥+⌘+1`)
4. Click on the folder icon 📁 and select your Swift project directory (parent of `swift`)
5. It may be necessary to close and reopen this project for Xcode to pick up the new location and display all source folders under "Swift" source folder. 

## First Steps

### Standard Library

Using `⇧+⌘+O`, locate file named `Print.swift`, and put a breakpoint in the `print` function. Run the app. 

### Runtime

Using `⇧+⌘+O`, locate file named `Metadata.cpp`, and put a breakpoint in the `swift::swift_initClassMetadata2` function. Run the app.
