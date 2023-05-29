PARAM(
    [PARAMETER(
        MANDATORY = $TRUE,
        VALUEFROMPIPELINE = $FALSE,
        VALUEFROMPIPELINEBYPROPERTYNAME = $FALSE)]
    [VALIDATENOTNULL()]
    [STRING]
    $ServerUrl
)

$script:handlers = @{}

function Register-Handler {
	param(
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[string]
		$path,
		
		[Parameter(Mandatory = $true)]
		[ValidateNotNull()]
		[ScriptBlock]
		$handler
	)
	$script:handlers[$path] = $handler
}

function Start-HttpListener {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false)]
        [ValidateNotNull()]
        [string]
        $Url
    )

    $listener = New-Object -Type 'System.Net.HttpListener'
    $listener.AuthenticationSchemes = [System.Net.AuthenticationSchemes]::Anonymous
	if (-not $Url.EndsWith('/')) {
		$Url += '/'
	}
    $listener.Prefixes.Add($Url)
	Write-Host "Http Server listens on: $Url"

	while($true) {
		try {
			$listener.Start()

			$context = $listener.GetContext()

			# Read Input Stream
			$buffer = New-Object 'byte[]' -ArgumentList 1024
			$ms = New-Object 'IO.MemoryStream'
			$read = 0
			while (($read = $context.Request.InputStream.Read($buffer, 0, 1024)) -gt 0) {
				$ms.Write($buffer, 0, $read);
			}
			$bodyData = $ms.ToArray()
			$ms.Dispose()
			
			$path = $context.Request.Url.AbsolutePath

			$handled = $false
			
			$handler = $script:handlers[$path]
			if ($handler) {
				$responseBody = & $handler $context.Request
				if ($responseBody -ne $null) {
					if ($responseBody -is [System.Net.HttpStatusCode]) {
						$context.Response.StatusCode = [int]($responseBody)
					} elseif ($responseBody -is [PSCustomObject]) {
						$context.Response.Headers = New-Object 'System.Net.WebHeaderCollection'
						$context.Response.Headers.Add('Content-Type', 'application/json')

						$body =  [system.Text.Encoding]::UTF8.GetBytes(($responseBody | ConvertTo-Json -Depth 10))
						$context.Response.ContentLength64 = $body.Length
						$context.Response.OutputStream.Write($body, 0, $body.Length)
						$context.Response.OutputStream.Flush()
						$context.Response.OutputStream.Close()
						
						$context.Response.StatusCode = [int]([System.Net.HttpStatusCode]::Ok)
					}
				}
			}

			if (-not $handled) {
				$context.Response.StatusCode = [int]([System.Net.HttpStatusCode]::NotFound)
			}
			$context.Response.Close()
		}
		catch {
			Write-Error $_
			$context.Response.StatusCode = [int]([System.Net.HttpStatusCode]::InternalServerError)
			$context.Response.Close();
		}
		finally {
			$listener.Stop()
		}
	}
}

Register-Handler -path '/api/v1/about' -handler {
	param($httpRequest)
	
	return [PSCustomObject]@{
		'About' = 'This is an example PS Http Service'
	}	
}

Start-HttpListener -Url $ServerUrl
