@echo off
rem ============================================================================
rem MGR1 HLS build - Vitis HLS 2024.2 (Windows FPGA host)
rem Stage gates per docs/07-vivado-runbook.md:
rem   1. csim must reproduce the Python oracle bit-exactly (score -7226)
rem   2. csynth runs only after csim PASS
rem   3. cosim must reproduce the same integers through the generated RTL
rem   4. export_design -format ip_catalog stages the IP for vivado/shell.tcl
rem Every completed stage appends one row to results\run_ledger.csv.
rem ============================================================================
setlocal

set HLS_HOME=C:\Xilinx\Vitis_HLS\2024.2
if not exist "%HLS_HOME%\bin\vitis_hls.bat" (
    echo ERROR: vitis_hls.bat not found under %HLS_HOME% - edit HLS_HOME
    exit /b 2
)

pushd hls\gru_sequence
echo === [%DATE% %TIME%] vitis_hls -f build.tcl - gru_sequence ===
call "%HLS_HOME%\bin\vitis_hls.bat" -f build.tcl
if errorlevel 1 (
    echo FAILED: gru_sequence - see vitis_hls.log
    popd
    exit /b 1
)
echo %DATE% %TIME% hls gru_sequence csim+csynth+cosim+export COMPLETE >> ..\..\results\run_ledger.csv
popd

pushd hls\mnv2_features
echo === [%DATE% %TIME%] vitis_hls -f build.tcl - mnv2_features ===
call "%HLS_HOME%\bin\vitis_hls.bat" -f build.tcl
if errorlevel 1 (
    echo FAILED: mnv2_features - see vitis_hls.log
    popd
    exit /b 1
)
echo %DATE% %TIME% hls mnv2_features csim+csynth+cosim+export COMPLETE >> ..\..\results\run_ledger.csv
popd

echo "=== both HLS flows COMPLETE - run vivado/shell.tcl next ==="
endlocal
