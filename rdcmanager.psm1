Function Get-RDCManConfigFile  {
    
<#
    .Synopsis
        Retrieves an RDC Manager config file

    .Description
        Retrieves an XML doc that contains the RDC Manager Config File

    .Parameter ComputerName
        Name of the computer where the config file resides.

    .Parameter FullPath
        Full path, including file name, of the config file.

    .Example
        Get a config file from a remote computer

        Get-RDCManConfigFile -Computername ServerA -FullPath c:\servers.rdg

    .Notes
        Author : Jeff Buenting
        Date : 2018 APR 04

#>

    [CmdletBinding()]
    Param (
        [String]$ComputerName = $env:COMPUTERNAME,

        [Parameter ( ValueFromPipeLine = $True )]
        [String[]]$FullPath
    )

    Process {
        Foreach ( $F in $Fullpath ) {
            Write-Verbose "Retriving config file : $F"
            if ( $ComputerName -ne $env:COMPUTERNAME ) {
                Write-Verbose "On Remote Computer : $ComputerName"
                $F = "\\$ComputerName\$($F -Replace ':','$')"
            }

            Try {
                Write-Output ([XML](Get-Content -Path $F -ErrorAction Stop))
            }
            Catch {
                $EXceptionMessage = $_.Exception.Message
                $ExceptionType = $_.exception.GetType().fullname
                Throw "Get-RDCManConfigFile : There was an error retrieving the RDC Manager Config File : $F.`n`n     $ExceptionMessage`n`n     Exception : $ExceptionType"   
            }
        }
    }
}

# ------------------------------------------------------------------------------------

Function Get-RDCManGroup {

<#
    .Synopsis
        Retrieves the server groups from the config file
#>    

    [cmdletBinding()]
    param (
        [Parameter( Mandatory = $True, ValueFromPipeline = $True )]
        [xml[]]$Config,

        [System.Xml.XmlElement]$XMLNode 
    )
   
    Process {
        Foreach ( $C in $Config ) {
            if ( -Not $XMLNode ) {
                $XMLNode = $C.RDCMan.File
            }
           

          $XMLNode.Group | foreach {
              $_ | FL 
              "-----"
              Get-RDCManGroup -Config $C -xmlNode $_
              "======"
          }
        }
    }
}

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------

