# Windows Dev Environment Config

<table>
  <tr>
    <td><img src="assets/1.webp" alt="Screenshot 1" width="400" /></td>
    <td><img src="assets/2.webp" alt="Screenshot 2" width="400" /></td>
  </tr>
  <tr>
    <td><img src="assets/3.webp" alt="Screenshot 3" width="400" /></td>
    <td><img src="assets/4.webp" alt="Screenshot 4" width="400" /></td>
  </tr>
</table>

(wallpaper link : https://steamcommunity.com/sharedfiles/filedetails/?id=3016260238)

## Contents

```
PowerShell/
  Microsoft.PowerShell_profile.ps1   # Console customizations & helper functions
  Modules/
    Terminal-Icons/0.11.0/           # Vendored Terminal-Icons module (icons & colors)
windhawk/                            # Windhawk tweak configurations
assets/                              # Reference images (wallpapers / screenshots)
README.md
```



## Features

- Enhanced PowerShell prompt (admin awareness, window title)
- Rich file/directory icons & color themes via Terminal-Icons
- Fast navigation & file helpers (mkcd, nf, ff, la, ll, grep, tail/head)
- Git workflow shortcuts (gs, ga, gc, gp, gcom, lazyg)
- System utilities (uptime, df, flushdns, Get-PubIP, trash)
- Environment bootstrap + cache cleaning
- Windhawk taskbar & UI tweaks (size, styling, clock)


## Windhawk Configs

See:
- [`modList.md`](windhawk/modList.md)
- JSON tweak files: [`clock.json`](windhawk/clock.json), [`taskbarSize.json`](windhawk/taskbarSize.json), [`taskbaricon.json`](windhawk/taskbaricon.json), [`taskbarstyler.json`](windhawk/taskbarstyler.json)

Import these via Windhawk UI to apply taskbar and clock customizations.
