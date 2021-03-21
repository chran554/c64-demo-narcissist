#!/bin/bash

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

assemblerFile=$1
projectFileDir=$2

# Get absolute path for supplied project path (no relative path)
cd $projectFileDir
projectFileDir=$(pwd)
cd -

assemblerFileWithExtension=$(basename -- "$assemblerFile")
extension="${assemblerFileWithExtension##*.}"
filename="${assemblerFileWithExtension%.*}"

tools_path="/Users/christian/Projects/c64/tools"
exomizer_exec="${tools_path}/Exomizer/Exomizer_3.02/exomizer"
kickass_jar="${tools_path}/KickAssembler/KickAssembler_v5.16/KickAss.jar"
vice_exec="${tools_path}/vice/vice-sdl2-3.4-r37694/x64sc.app/Contents/MacOS/x64sc"
#debug_exec="${tools_path}/c64_debugger/C64_65XE_Debugger_v0.64.58/C64_Debugger.app/Contents/MacOS/C64Debugger"
debug_exec="${tools_path}/c64_debugger/C64_65XE_NESDebugger_v0.64.58.4/C64 Debugger.app/Contents/MacOS/C64 Debugger"
cc1541_exec="${tools_path}/cc1541/cc1541_v3.2/cc1541"

target_path="${projectFileDir}/target"
assemblerAbsoluteFile="${projectFileDir}/${assemblerFile}"
originalProgramFile="${target_path}/${filename}.original.prg"
finalProgramFile="${target_path}/${filename}.prg"
viceMonitorCommandsFile="${target_path}/${filename}.vs"
c64_disc_file="${target_path}/${filename}.d64"

echo
echo "Cleaning previous builds"
echo "Recreating path: ${target_path}"
echo "--------------------------------------------------"
rm -rf "${target_path}"
mkdir "${target_path}"

echo
echo "Compiling file"
echo "Input file:  ${assemblerAbsoluteFile}"
echo "Output file: ${originalProgramFile}"
echo "--------------------------------------------------"
java -jar $kickass_jar -symbolfile -vicesymbols -odir "${target_path}" -o "${originalProgramFile}" "${assemblerAbsoluteFile}"

echo
echo "Crunching file"
echo "Input file:  ${originalProgramFile}"
echo "Output file: ${finalProgramFile}"
echo "--------------------------------------------------"
$exomizer_exec sfx systrim -B "${originalProgramFile}" -o "${finalProgramFile}"

#"${debug_exec}" --help
#echo "Debugger path: ${debug_exec}"

echo
echo "Creating C64 disc file"
echo "Input file:  ${finalProgramFile}"
echo "Output file: ${c64_disc_file}"
echo "--------------------------------------------------"
"${cc1541_exec}" -n "${filename}" -f "${filename}" -w "${finalProgramFile}" "${c64_disc_file}"

echo
echo "--------------------------------------------------"
echo "Project dir:          ${projectFileDir}/"
echo "Compiling file:       ${assemblerFile}"
echo "Final program file:   ${finalProgramFile}"
echo "C64 disc file:        ${c64_disc_file}"
echo "--------------------------------------------------"

"${debug_exec}" -prg "${finalProgramFile}" -wait 2000 -autojmp
#$vice_exec -moncommands "${viceMonitorCommandsFile}" -autostartprgmode 1 "${finalProgramFile}"
