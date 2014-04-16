####
#
# Installs bitcoind from source
#
class bitcoind::source (

    $gitbranch = 'master',
    $walletEnabled = false,
    $debug = false

    ) {

    include bitcoind::params

    notify{"Starting build of bitcoind.... This may take a while": }
    if $debug {
        notify{"NOTE:If you get an error at this stage, enlarge the swap file to 1GB. See - https://bitcointalk.org/index.php?topic=110627.0": }
    }

    # 1GB SWAPFILE CODE
    #
    # sudo dd if=/dev/zero of=/swapfile bs=64M count=16
    # sudo mkswap /swapfile
    # sudo swapon /swapfile

    $repository = "git://github.com/bitcoin/bitcoin.git"
    $clone_path = "/opt/bitcoin"
    $install_path = "/usr/bin"

    # Default required packages
    $requires   = [
        "git",
        "build-essential",
        "libtool",
        "autotools-dev",
        "autoconf",
        "libssl-dev",
        "libboost-all-dev",
        "libminiupnpc-dev",
        "pkg-config"
    ]

    package { $requires:
        ensure => present,
    }

    # Berkeley DB 4.8 is only required for
    if $walletEnabled {
        $requires = [
            "libdb4.8-dev",
            "libdb4.8++-dev"
        ]
        package { $requires:
            ensure => present
        }
    }

    file { $clone_path:
        ensure => directory,
    }

    exec { "git clone bitcoin":
        path      => "/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:/usr/bin:/usr/sbin:/bin:/sbin:.",
        command   => "git clone ${repository} ${clone_path}",
        creates   => "${clone_path}/.git",
        logoutput => true
    }
    exec { "bitcoin-autogen":
        path      => "/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:/usr/bin:/usr/sbin:/bin:/sbin:.",
        command   => "./autogen.sh",
        creates   => "${clone_path}/configure",
        cwd       => "${clone_path}",
        logoutput => on_failure,
        timeout   => 0,
    }

    $configureOptions = $walletEnabled ? {
        false => '--disable-wallet',
        true => ''
    }
    exec { "bitcoin-configure":
        require   => Exec["bitcoin-autogen"],
        path      => "/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:/usr/bin:/usr/sbin:/bin:/sbin:.",
        command   => "./configure ${configureOptions}",
        creates   => "${clone_path}/src/bitcoind",
        cwd       => "${clone_path}",
        logoutput => on_failure,
        timeout   => 0,
    }

    exec { "bitcoin-make":
        require   => Exec["bitcoin-configure"],
        path      => "/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:/usr/bin:/usr/sbin:/bin:/sbin:.",
        command   => "make",
        creates   => "${clone_path}/src/bitcoind",
        cwd       => "${clone_path}",
        logoutput => on_failure,
        timeout   => 0,
    }

    exec { "copy binary":
        path      => "/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:/usr/bin:/usr/sbin:/bin:/sbin:.",
        command   => "cp ${clone_path}/src/bitcoind ${install_path}",
        creates   => "${install_path}/bitcoind",
        logoutput => true
    }

}
