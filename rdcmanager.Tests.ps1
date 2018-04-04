$ModulePath = Split-Path -Parent $MyInvocation.MyCommand.Path

$ModuleName = $ModulePath | Split-Path -Leaf

# ----- Remove and then import the module.  This is so any new changes are imported.
Get-Module -Name $ModuleName -All | Remove-Module -Force -Verbose

Import-Module "$ModulePath\$ModuleName.PSD1" -Force -ErrorAction Stop -Verbose

#-------------------------------------------------------------------------------------
# ----- Check if all fucntions in the module have a unit tests

Describe "$ModuleName : Module Tests" {

    $Module = Get-module -Name $ModuleName

    $testFile = Get-ChildItem $module.ModuleBase -Filter '*.Tests.ps1' -File
    
    $testNames = Select-String -Path $testFile.FullName -Pattern '[D|d]escribe\s[^\$](.+)?\s+{' | ForEach-Object {
        [System.Management.Automation.PSParser]::Tokenize($_.Matches.Groups[1].Value, [ref]$null).Content
    }

    $moduleCommandNames = (Get-Command -Module $ModuleName | where commandtype -ne alias  )

    it 'should have a test for each function' {
        Compare-Object $moduleCommandNames $testNames | where { $_.SideIndicator -eq '<=' } | select inputobject | should beNullOrEmpty
    }
}

#-------------------------------------------------------------------------------------

Write-Output "`n`n"

Describe "$Module : Get-RDCManConfigFile" {

    # ----- Get Function Help
    # ----- Pester to test Comment based help
    # ----- http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-comment-based.html
    Context "Help" {

        $H = Help Get-RDCManConfigFile -Full

        # ----- Help Tests
        It "has Synopsis Help Section" {
            $H.Synopsis | Should Not BeNullorEmpty
        }

        It "has Description Help Section" {
            $H.Description | Should Not BeNullorEmpty
        }

        It "has Parameters Help Section" {
            $H.Parameters | Should Not BeNullorEmpty
        }

        # Examples
        it "Example - Count should be greater than 0"{
            $H.examples.example.code.count | Should BeGreaterthan 0
        }
            
        # Examples - Remarks (small description that comes with the example)
        foreach ($Example in $H.examples.example)
        {
            it "Example - Remarks on $($Example.Title)"{
                $Example.remarks | Should not BeNullOrEmpty
            }
        }

        It "has Notes Help Section" {
            $H.alertSet | Should Not BeNullorEmpty
        }
    }  

    Context Execution {
        It "Throws an error if the file fails to load" {      
            {Get-RDCManConfigFile -FullPath TestDrive:\servers.rdg } | Should Throw
        }

        It "Does not throw an error if successful" {
            Mock -CommandName Get-Content -MockWith {
                $XML = [XML]'<CRMSetup/>'
                Write-Output $XML
            }

            {Get-RDCManConfigFile -FullPath TestDrive:\servers.rdg } | Should Not Throw
        }
    }

    Context Output {
        It "Returns an XML object" {
             Mock -CommandName Get-Content -MockWith {
                $XML = [XML]'<CRMSetup/>'
                Write-Output $XML
            }

            Get-RDCManConfigFile -FullPath TestDrive:\servers.rdg | Should beoftype XML
        }
    }

}