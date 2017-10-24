Function Test-IsOffline
{
    return Test-Path c:\Temp\Tests\Offline.config
}

Function Find-V4Installer
{
    return (gci C:\temp\Tests | ? {$_.Name -like "Octopus.4s.*.msi"} | select -first 1 | select -expand Name)
}

Function Find-V3Installer
{
    return (gci C:\temp\Tests | ? {$_.Name -like "Octopus.3.*.msi"} | select -first 1 | select -expand Name)
}

if(Test-IsOffline)
{
    $downloadUrl = Find-V4Installer
}
else
{
    $downloadUrl = "https://octopus.com/downloads/latest/WindowsX64/OctopusServer"   # when 4.0 drops, this should change!
}


Configuration Server_Scenario_01_Install
{
    Import-DscResource -ModuleName OctopusDSC

    $pass = ConvertTo-SecureString "SuperS3cretPassw0rd!" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("OctoAdmin", $pass)

    $svcpass = ConvertTo-SecureString "HyperS3cretPassw0rd!" -AsPlainText -Force
    $svccred = New-Object System.Management.Automation.PSCredential ("OctoSquid", $svcpass)


    Node "localhost"
    {
        LocalConfigurationManager
        {
            DebugMode = "ForceModuleImport"
        }

        User OctoSquid
        {
            Ensure = "Present"
            UserName = "OctoSquid"
            Password = $svccred
            PasswordChangeRequired = $false 
        }

        cOctopusServer OctopusServer
        {
            Ensure = "Present"
            State = "Started"

            # Server instance name. Leave it as 'OctopusServer' unless you have more
            # than one instance
            Name = "OctopusServer"

            # The url that Octopus will listen on
            WebListenPrefix = "http://localhost:81"

            SqlDbConnectionString = "Server=(local)\SQLEXPRESS;Database=Octopus;Trusted_Connection=True;"

            # The admin user to create
            OctopusAdminCredential = $cred

            # dont mess with stats
            AllowCollectionOfAnonymousUsageStatistics = $false

            # DownloadUrl = "https://s3-ap-southeast-1.amazonaws.com/octopus-testing/server/Octopus.4.0.0-v4-14812.msi"
            DownloadUrl = $downloadUrl

            OctopusServiceCredential = $svccred 
            DependsOn = "[user]OctoSquid"
        }

        cOctopusServerUsernamePasswordAuthentication "Enable Username/Password Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }

        cOctopusServerGuestAuthentication "Enable Guest Login"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
        }

        cOctopusServerActiveDirectoryAuthentication "Enable Active Directory Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            AllowFormsAuthenticationForDomainUsers = $true
            ActiveDirectoryContainer = "CN=Users,DC=GPN,DC=COM"
        }

        cOctopusServerAzureADAuthentication "Enable Azure AD Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://login.microsoftonline.com/b91ebf6a-84be-4c6f-97f3-32a1d0a11c8a"
            ClientID = "0272262a-b31d-4acf-8891-56e96d302018"
        }

        cOctopusServerOktaAuthentication "Enable Okta Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            Issuer = "https://dev-258251.oktapreview.com"
            ClientID = "752nx5basdskrsbqansE"
        }

        cOctopusServerGoogleAppsAuthentication "Enable GoogleApps Auth"
        {
            InstanceName = "OctopusServer"
            Enabled = $true
            ClientID = "5743519123-1232358520259-3634528"
            HostedDomain = "https://octopus.example.com"
        }
    }
}