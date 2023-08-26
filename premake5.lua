-- Function to check endianness
function checkEndianness()
    local checkEndiannessScript = [[
        #include <iostream>
        #include <cstdint>
        int main() {
            uint32_t testValue = 1;
            if (*((uint8_t*)&testValue) == 1) {
                std::cout << "LITTLE_ENDIAN";
            } else {
                std::cout << "BIG_ENDIAN";
            }
            return 0;
        }
    ]]

    local checkEndiannessFile = "_check_endianness.cpp"
    local checkEndiannessExe = "_check_endianness"

    -- Write the C++ code to a temporary file
    local file = io.open(checkEndiannessFile, "w")
    file:write(checkEndiannessScript)
    file:close()

    -- Compile and run the C++ program
    local compileCommand = "g++ " .. checkEndiannessFile .. " -o " .. checkEndiannessExe
    local runCommand = "./" .. checkEndiannessExe

    local handle = io.popen(compileCommand)
    handle:close()
    handle = io.popen(runCommand)
    local endianness = handle:read("*a")
    handle:close()

    -- Clean up temporary files
    os.remove(checkEndiannessFile)
    os.remove(checkEndiannessExe)

    return endianness
end

project "sndfile"
    kind "StaticLib"
	architecture "x86_64"
    language "C"
    location "build"
    configurations { "Debug", "Release", "Dist" }
    platforms { "Windows", "Linux" }

    objdir "build/obj/%{cfg.buildcfg}"
    targetdir "build/bin/%{cfg.buildcfg}"

    includedirs
    {
        "src/",
        "src/ALAC/",
        "src/G72x/",
        "src/GSM610/",
        "include/"
    }
    
    files
    {
        "src/*.c",
        "src/ALAC/*.c",
        "src/G72x/*.c",
        "src/GSM610/*.c"
    }
    
    projectName = "%{prj.name}"
    projectVersion = 1
    defines { "PACKAGE_NAME=\"" .. projectName .. "\"" }
    defines { "PACKAGE_VERSION=\"" .. projectVersion .. "\"" }
    defines { "CPU_CLIPS_POSITIVE=" .. 0 .. "" }
    defines { "CPU_CLIPS_NEGATIVE=" .. 0 .. "" }
    defines { "HAVE_SYS_TYPES_H=" .. 1 .. "" }
    defines { "M_PI=" .. 3.14159 .. "" }

    filter "platforms:Windows"
        system "Windows"
        defines { "USE_WINDOWS_API=" .. 1 .. "" }
        defines { "OS_IS_WIN32=" .. 1 .. "" }
        defines { "CPU_IS_LITTLE_ENDIAN=" .. 1 .. "" }
        defines { "CPU_IS_BIG_ENDIAN=" .. 0 .. "" }

    filter "platforms:Linux"
        system "Linux"
        defines { "HAVE_UNISTD_H" }
        defines { "OS_IS_WIN32=" .. 0 .. "" }
        endianness = checkEndianness()
        
        defines { "USE_WINDOWS_API=" .. 0 .. "" }
        if endianness == "BIG_ENDIAN" then
            bigendian = 1
            littleendian = 0
            defines { "CPU_IS_LITTLE_ENDIAN=" .. littleendian .. "" }
            defines { "CPU_IS_BIG_ENDIAN=" .. bigendian .. "" }
        end
    
        if endianness == "LITTLE_ENDIAN" then
            bigendian = 0
            littleendian = 1
            defines { "CPU_IS_LITTLE_ENDIAN=" .. littleendian .. "" }
            defines { "CPU_IS_BIG_ENDIAN=" .. bigendian .. "" }
        end

    filter "configurations:Debug"
		runtime "Debug"
		symbols "on"

	filter "configurations:Release"
		runtime "Release"
		optimize "speed"

    filter "configurations:Dist"
		runtime "Release"
		optimize "speed"
