describe 'Build' {

    BeforeAll {

        # $moduleName         = 'TestModule'
        # $manifest           = Import-PowerShellDataFile -Path $env:BHPSModuleManifest
        # $outputDir          = [IO.Path]::Combine($env:BHProjectPath, 'Output')
        # $outputModDir       = [IO.Path]::Combine($outputDir, $env:BHProjectName)
        # $testModuleOutputPath         = [IO.Path]::Combine($outputModDir, $manifest.ModuleVersion)
        $testModuleOutputPath = [IO.Path]::Combine($env:BHProjectPath, 'tests', 'TestModule', 'Output', 'TestModule', '0.1.0')

        #$manifest   = Test-ModuleManifest -Path $PSScriptRoot/TestModule/TestModule/TestModule.psd1
        #$testModuleOutputPath = "$PSScriptRoot/TestModule/Output/TestModule/$($manifest.Version)"
    }

    context 'Compile module' {
        BeforeAll {

            Write-Host "PSScriptRoot: $PSScriptRoot"
            Write-Host "OutputPath: $testModuleOutputPath"

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

            #Write-Host (Get-ChildItem "$PSScriptRoot/TestModule/Output" -Recurse | Format-List | Out-String)
        }

        AfterAll {
            Remove-Item $testModuleOutputPath -Recurse -Force
        }

        it 'Creates module' {
            $testModuleOutputPath | Should -Exist
        }

        it 'Has PSD1 and monolithic PSM1' {
            (Get-ChildItem -Path $testModuleOutputPath -File).Count | Should -Be 2
            "$testModuleOutputPath/TestModule.psd1"                 | Should -Exist
            "$testModuleOutputPath/TestModule.psm1"                 | Should -Exist
            "$testModuleOutputPath/Public"                          | Should -Not -Exist
            "$testModuleOutputPath/Private"                         | Should -Not -Exist
        }

        it 'Has module header text' {
            "$testModuleOutputPath/TestModule.psm1" | Should -FileContentMatch '# Module Header'
        }

        it 'Has module footer text' {
            "$testModuleOutputPath/TestModule.psm1" | Should -FileContentMatch '# Module Footer'
        }

        it 'Has function header text' {
            "$testModuleOutputPath/TestModule.psm1" | Should -FileContentMatch '# Function header'
        }

        it 'Has function hfootereader text' {
            "$testModuleOutputPath/TestModule.psm1" | Should -FileContentMatch '# Function footer'
        }

        it 'Does not contain excluded files' {
            (Get-ChildItem -Path $testModuleOutputPath -File -Filter '*excludeme*' -Recurse).Count | Should -Be 0
            "$testModuleOutputPath/TestModule.psm1" | Should -Not -FileContentMatch '=== EXCLUDE ME ==='
        }

        it 'Has MAML help XML' {
            "$testModuleOutputPath/en-US/TestModule-help.xml" | Should -Exist
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
            Remove-Item $testModuleOutputPath -Recurse -Force
        }

        it 'Creates module' {
            $testModuleOutputPath | Should -Exist
        }

        it 'Has PSD1 and dot-sourced functions' {
            (Get-ChildItem -Path $testModuleOutputPath).Count | Should -Be 6
            "$testModuleOutputPath/TestModule.psd1"           | Should -Exist
            "$testModuleOutputPath/TestModule.psm1"           | Should -Exist
            "$testModuleOutputPath/Public"                    | Should -Exist
            "$testModuleOutputPath/Private"                   | Should -Exist
        }

        it 'Does not contain excluded stuff' {
            (Get-ChildItem -Path $testModuleOutputPath -File -Filter '*excludeme*' -Recurse).Count | Should -Be 0
        }

        it 'Has MAML help XML' {
            "$testModuleOutputPath/en-US/TestModule-help.xml" | Should -Exist
        }
    }
}
