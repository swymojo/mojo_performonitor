This performance monitor allows developers and server owners to view the recent performance of the scripts they have created in detail, thanks to trend-based load analysis and Deep Inject metrics.

The weight of scripts on the server, load fluctuations, baseline reports, and trend scores can be monitored. NUI calls can be counted, sample counts can be calculated, your scripts' help calls and the event name can be printed with the report it provided in the last event, and it reports to your Discord server via Webhook by checking whether the script is stable within the time you specify.

When the server starts, the files you inject for your script monitoring begin collecting samples. For accurate reporting, we pause the loop for a while and take the average after collecting the specified number of samples. This way, you avoid reporting sudden calls and observe whether the performance is truly good or just keeping you awake by taking the average of the samples.

"Note: You can inject as many scripts as you want. However, the more scripts, the more server fatigue it means. mojo_performonitor will strain your server with so many calls. Therefore, we recommend using it only for script testing."

You can customize the script however you like and make additions. I created it so I could get what I needed and left it that way. I do not provide support for the project. The customizable settings and comments in the Base Code have been corrected using artificial intelligence.

To avoid causing problems with the existing state, it does not touch the original infrastructure of the scripts. If you want more precise measurements, you should enter the following around the heavy functions within the target scripts:

local perf = exports[“mojo_performonitor”]

local t0 = GetGameTimer()
-- heavy task
perf:MOJO_USE(“SomeSection”, GetGameTimer() - t0)

Otherwise, you will only capture superficial numbers that resemble each other with averages. The code above enables pinpoint detection and target capture. It is recommended for critical projects. Otherwise, it won't have much of an effect.

Installation:

1) Make sure to start the script by placing mojo_performonitor in any of the folders you specified in the resource file.
2) The mojo_injection.lua file in the folder is your reporting tool. Place it in the client folder within the script you want to report on. Create it if it doesn't exist.
3) In the Fxmanifest file, ensure the following sections are present:
client_scripts {
    ‘client/mojo_inject.lua’
}

and

dependencies {
    ‘mojo_performonitor ’
}

If not added to dependencies and client_scripts, it will not work because it actively retrieves data.

<img width="500" height="673" alt="image" src="https://github.com/user-attachments/assets/8e98e4ef-9f63-4442-8719-14f0c3b2267d" /> <img width="500" height="673" alt="image" src="https://github.com/user-attachments/assets/c70353a9-0ffe-47a4-aa23-ad406aa3f1eb" /> <img width="500" height="673" alt="image" src="https://github.com/user-attachments/assets/477e8e09-65a3-44e2-ad3a-8f74f2faa105" />


