Add-Type -AssemblyName System.Speech
$s = New-Object -TypeName System.Speech.Synthesis.SpeechSynthesizer
$s.Speak("this is a test")
$s.Speak("woah it works")