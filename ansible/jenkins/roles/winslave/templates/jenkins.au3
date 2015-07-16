Local $sUserName = "jenkins"
Local $sPassword = "{{jenkins_pass}}"
RunAs($sUserName, @ComputerName, $sPassword, 1, "cmd /C echo")

