describe 'Build' {

    BeforeAll {

        $moduleName         = $env:BHProjectName
        $manifest           = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
        $outputDir          = [IO.Path]::Combine($env:BHProjectPath, 'Output')
        $outputModDir       = [IO.Path]::Combine($outputDir, $env:BHProjectName)
        $outputPath         = [IO.Path]::Combine($outputModDir, $manifest.ModuleVersion)

        #$manifest   = Test-ModuleManifest -Path $PSScriptRoot/TestModule/TestModule/TestModule.psd1
        #$outputPath = "$PSScriptRoot/TestModule/Output/TestModule/$($manifest.Version)"
    }

    context 'Compile module' {
        BeforeAll {

            Write-Host "PSScriptRoot: $PSScriptRoot"
            Write-Host "OutputPath: $outputPath"

            # build is PS job so psake doesn't freak out because it's nested
            Start-Job -ScriptBlock {
                Set-Location $using:PSScriptRoot/TestModule
                $global:PSBuildCompile = $true
                ./build.ps1 -Task Build
            } | Wait-Job

            # Start-Job -ScriptBlock {
            #     # Set-Location /home/runner/work/PowerShellBuild/PowerShellBuild/tests/TestModule
            #     Set-Location C:\Users\Brandon\OneDrive\Documents\GitHub\psake\PowerShellBuild\tests\TestModule
            #     $global:PSBuildCompile = $true
            #     ./build.ps1 -Task Build
            # } | Wait-Job

            Write-Host (Get-ChildItem "$PSScriptRoot/TestModule/Output" -Recurse | Format-List | Out-String)
        }

        AfterAll {
            # Remove-Item "$PSScriptRoot/TestModule/Output" -Recurse -Force
        }

        it 'Creates module' {
            $outputPath | Should -Exist
        }

        it 'Has PSD1 and monolithic PSM1' {
            (Get-ChildItem -Path $outputPath -File).Count | Should -Be 2
            "$outputPath/TestModule.psd1"                 | Should -Exist
            "$outputPath/TestModule.psm1"                 | Should -Exist
            "$outputPath/Public"                          | Should -Not -Exist
            "$outputPath/Private"                         | Should -Not -Exist
        }

        it 'Has module header text' {
            "$outputPath/TestModule.psm1" | Should -FileContentMatch '# Module Header'
        }

        it 'Has module footer text' {
            "$outputPath/TestModule.psm1" | Should -FileContentMatch '# Module Footer'
        }

        it 'Has function header text' {
            "$outputPath/TestModule.psm1" | Should -FileContentMatch '# Function header'
        }

        it 'Has function hfootereader text' {
            "$outputPath/TestModule.psm1" | Should -FileContentMatch '# Function footer'
        }

        it 'Does not contain excluded files' {
            (Get-ChildItem -Path $outputPath -File -Filter '*excludeme*' -Recurse).Count | Should -Be 0
            "$outputPath/TestModule.psm1" | Should -Not -FileContentMatch '=== EXCLUDE ME ==='
        }

        it 'Has MAML help XML' {
            "$outputPath/en-US/TestModule-help.xml" | Should -Exist
        }
    }

    context 'Dot-sourced module' {
        BeforeAll {
            # build is PS job so psake doesn't freak out because it's nested
            Start-Job -ScriptBlock {
                Set-Location $using:PSScriptRoot/TestModule
                $global:PSBuildCompile = $false
                ./build.ps1 -Task Build
            } | Wait-Job
        }

        AfterAll {
            Remove-Item "$PSScriptRoot/TestModule/Output" -Recurse -Force
        }

        it 'Creates module' {
            $outputPath | Should -Exist
        }

        it 'Has PSD1 and dot-sourced functions' {
            (Get-ChildItem -Path $outputPath).Count | Should -Be 6
            "$outputPath/TestModule.psd1"           | Should -Exist
            "$outputPath/TestModule.psm1"           | Should -Exist
            "$outputPath/Public"                    | Should -Exist
            "$outputPath/Private"                   | Should -Exist
        }

        it 'Does not contain excluded stuff' {
            (Get-ChildItem -Path $outputPath -File -Filter '*excludeme*' -Recurse).Count | Should -Be 0
        }

        it 'Has MAML help XML' {
            "$outputPath/en-US/TestModule-help.xml" | Should -Exist
        }
    }
}