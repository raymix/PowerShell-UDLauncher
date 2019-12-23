New-UDTheme -Name 'Branded' -Definition @{
    UDDashboard = @{
        BackgroundColor = "rgba(33, 87, 50, 1)"
        FontColor       = "#000"
        'Background'    = 'url(https://i.imgur.com/RDjFc06.jpg) left top no-repeat; background-repeat: repeat;'
        'background-size' = '100px 100px'
        'border-left' = '3px solid #ba0c2f'
        'font-family' = 'effra, sans-serif'
    }

    '.sidenav' = @{
        'background-color' = '#FFF'
        'border-right' = '3px solid #ba0c2f'
    }

    '.divider' = @{
        'height' = '1px'
    }
    '.sidenav li.active' = @{
        'background-color' = 'rgba(0,0,0,0)'
    }
    '.redline' = @{
        'height' = '60px'
        'text-align' = 'center'
        'position' = 'inherit'
        'background' = '#BA0C2F'
        'top' = '0px'
        'width' = '2px'
        'margin-bottom' = '10px'
        'display' = 'block'
        'margin' = '0 auto'
    }

    '.collapsible' = @{
        'border-top' = 'none'
        'border-right' = 'none'
        'border-left' = 'none'
    }

    '.collapsible-body' = @{
        'border-bottom' = 'none'
        'padding' = '1rem'
    }

    '.collapsible-header' = @{
        'padding' = '0.5rem'
        'background-color' = 'rgba(0,0,0,0.3)'
        'border-bottom' = '1px solid #BA0C2F'
    }

    '.imgBox' = @{
        'max-width '= '100%'
        'max-height' = '64px'
    }

    '.pBox' = @{
        'display' = 'block; margin: 0 auto'
        'text-align' = 'center'
        'font-weight' = '300'
        'font-size' = '20px'
        'text-shadow' = '2px 2px 2px rgba(0,0,0,0.4)'
        'color' = 'white'
    }

    '.card:hover' = @{
        'background-color' = 'rgba(186,12,47,0.6) !important'
        '-webkit-box-shadow' = 'inset 0px 0px 0px 1px #ba0c2f'
        '-moz-box-shadow '= 'inset 0px 0px 0px 1px #ba0c2f'
        'box-shadow' = 'inset 0px 0px 0px 1px #ba0c2f'
        'color' = 'white'
    }
    
    UDNavBar    = @{
        BackgroundColor = "rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDFooter    = @{
        BackgroundColor = "rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDCard      = @{
        BackgroundColor = "#rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDInput     = @{
        BackgroundColor = "#rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDGrid      = @{
        BackgroundColor = "#rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDChart     = @{
        BackgroundColor = "#rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDMonitor   = @{
        BackgroundColor = "#rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    UDTable     = @{
        BackgroundColor = "#rgba(33,87,50,0.5)"
        FontColor       = "#FFFFFF"
    }
    '.btn'      = @{
        'color'            = "#ffffff"
        'background-color' = "#a80000"
        
    }
    '.btn:hover'      = @{
        'color'            = "#ffffff"
        'background-color' = "#C70303"
    }
}
