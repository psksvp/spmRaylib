import Foundation
import CommonSwift


if CommandLine.arguments.count >= 2
{
  gen()
}




func gen()
{
  let projectName = String(cwdLastPathComponent())
  let packageDotSwift = """
  // swift-tools-version:5.3
  // The swift-tools-version declares the minimum version of Swift required to build this package.

  import PackageDescription

  let package = Package(
      name: "\(projectName)",
      platforms: [.macOS(.v10_15)],
      products: [.executable(name: "\(projectName)", targets: ["\(projectName)"]),
                 .library(name: "raylib", targets:["raylib"])
                ],
      dependencies: [],
      targets: [
          // Targets are the basic building blocks of a package. A target can define a module or a test suite.
          // Targets can depend on other targets in this package, and on products in packages this package depends on.
          .target(
              name: "\(projectName)",
              dependencies: ["raylib"]),
          .testTarget(
              name: "\(projectName)Tests",
              dependencies: ["\(projectName)"]),
          .target( name: "raylib",
                   dependencies: [],
                   sources: ["rayshim.c"],
                   publicHeadersPath: "include",
                   cSettings: [.headerSearchPath("./Dependencies/raylib/src")],
                   linkerSettings: [.unsafeFlags(["-L./Dependencies/raylib/src"]),
                                    .linkedLibrary("raylib"),
                                    .linkedFramework("CoreVideo"),
                                    .linkedFramework("CoreAudio"),
                                    .linkedFramework("IOKit"),
                                    .linkedFramework("Cocoa"),
                                    .linkedFramework("GLUT"),
                                    .linkedFramework("OpenGL")
                                   ]),
      ]
  )

  """
  
  //--------------------------------
  let rayShimH = """
  //
  //  Created by psksvp@gmail.com on 17/4/21.
  //
  
  #include "../../../Dependencies/raylib/src/raylib.h"
  #include "../../../Dependencies/raylib/src/raymath.h"
  """
  
  //--------------------------------
  let rayShimC = """
  //
  //  Created by psksvp@gmail.com on 17/4/21.
  //

  #include "rayshim.h"
  """
  
  //--------------------------------
  let mainSWIFT = """
  //
  //  Created by psksvp@gmail.com on 17/4/21.
  //
  import raylib


  print("Hello, world!")

  InitWindow(800, 450, "raylib [core] example - basic window");

  while !WindowShouldClose()
  {
      BeginDrawing()
          ClearBackground(Color(r: 255, g: 255, b: 255, a: 255))
          DrawText("Congrats! You created your first window!", 190, 200, 20, Color(r: 0, g: 255, b: 0, a: 255))
      EndDrawing()
  }

  CloseWindow()
  """
  
  
  ["/usr/bin/swift", "package", "init", "--type=executable"].spawn()
  FS.writeText(inString: packageDotSwift, toPath: "Package.swift")
  mkdir("./Dependencies")
  mkdir("./Sources/raylib/include")
  FS.writeText(inString: mainSWIFT, toPath: "./Sources/\(projectName)/main.swift")
  FS.writeText(inString: rayShimH, toPath: "./Sources/raylib/include/rayshim.h")
  FS.writeText(inString: rayShimC, toPath: "./Sources/raylib/rayshim.c")
  print("cloning raylib ... may take sometime.")
  runGIT()
}


func runGIT()
{
  let git = "/usr/bin/git"
  [git, "init"].spawn()
  [git, "add", "."].spawn()
  [git, "commit", "-m", "init commit"].spawn()
  [git, "submodule", "add", "https://github.com/raysan5/raylib", "./Dependencies/raylib"].spawn()
}


func searchAndReplace(_ p: [(String, String)], inString: String) -> String
{
  if p.count > 0
  {
    let (s, r) = p[0]
    let rs = inString.replacingOccurrences(of: s, with: r)
    return searchAndReplace(Array(p.dropFirst(1)), inString: rs)
  }
  else
  {
    return inString
  }
}

func moveFile(_ from: String, _ to: String)
{
  ["/bin/mv", from, to].spawn()
}

func catRead(_ path: String) -> String
{
  return ["/bin/cat", path].spawn()!
}

func catWrite(_ s: String, _ path: String)
{
  ["/bin/cat", ">", path].spawn(stdInput: s)
}

func mkdir(_ path:String)
{
  ["/bin/mkdir", "-p" , path].spawn()
}

func ls(_ dir: String) -> [Substring]
{
  return ["/bin/ls", dir].spawn()!.split(separator: "\n")
}

func cp(_ f: String, t: String)
{
  ["/bin/cp", f, t].spawn()
}

func rm(_ f: String)
{
  ["/bin/rm", "-f", f].spawn()
}

func cwdLastPathComponent() -> Substring
{
  let fs = FileManager.default
  return fs.currentDirectoryPath.split(separator: "/").last!
}
