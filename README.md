# GNTL Pool based on cryptonote-nodejs-pool
High performance Node.js (with native C addons) mining pool.
This is a customized version of the original pool, for GNTL Coin.

## Table of Contents
  - [Requirements](#requirements)
    - [Server Specification](#server-specification)
    - [Connectivity](#connectivity)
  - [Installation](#installation)
    - [Create Pool User](#create-pool-user)
    - [Install GNTL Node](#install-gntl-node)
    - [Install GNTL Pool](#install-gntl-pool)
  - [Configuration](#configuration)
    - [Configure Redis Server Service](#configure-redis-server-service)
    - [Create Pool Wallet](#create-pool-wallet)
      - [Create Wallet Password File](#create-wallet-password-file)
      - [Restore Pool Wallet](#restore-pool-wallet)
    - [Configure Caddy](#configure-caddy)
    - [Link Certificates](#link-certificates)
    - [Config JSON Changes](#config-json-changes)
    - [Config JS Changes](#config-js-changes)
    - [Create Processes](#create-processes)
  - [Additional Information](#additional-information)
    - [Back End Parameters](#back-end-parameters)
    - [Front End Parameters](#front-end-parameters)
    - [Upgrading](#upgrading)
    - [Features](#features)
    - [JSON-RPC Commands from CLI](#json-rpc-commands-from-cli)
    - [Monitoring Your Pool](#monitoring-your-pool)
    - [Pools Using This Software](#pools-using-this-software)
    - [Donations](#donations)
    - [Credits](#credits)
    - [License](#license)

## Requirements
### Server Specification
* 2 CPU Cores (with AES_NI)
* 4GB Ram
* 25GB SSD Storage
* Ubuntu Server 18.04 LTS (This is what we've tested on, but may work on other versions)
* SSH access

### Connectivity
* Domain Name (sub-domain is reccomended, e.g. gntl.domain.com)
* Public Static IP Address
* Firewall configured to allow inbound TCP ports for Pool:
```
80
443
10007
20007
30007
```

## Installation
### Create Pool User:
We'll create a pool user (the username is referenced in parts of the install, so ensure you mach it exactly), run the following, and follow the additional steps:
```
sudo adduser gntlpool
```

We'll grant the user password-less sudo privleges, run the following:
```
sudo usermod -aG sudo gntlpool
echo "gntlpool ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/gntl
```

We'll switch to the created user for the rest of the install, run the following:
```
sudo su - gntlpool
```

### Install GNTL Node
Follow the [GNTL Node](https://github.com/The-GNTL-Project/Documentation/wiki/GNTL-Node) setup steps to get the GNTL Node setup and the chain synched.

### Install GNTL Pool
Run the following to install via the bash script:
```
curl -o- https://raw.githubusercontent.com/The-GNTL-Project/cryptonote-nodejs-pool/master/deployment/deploy.bash | bash
```

## Configuration
### Configure Redis Server Service
Open up redis.conf for editing:
```
sudo nano /etc/redis/redis.conf
```
Search using the F6 key, for:
```
supervised no
```

Change it to the following, then save and exit nano:
```
supervised systemd
```

Enable the service:
```
sudo systemctl enable redis-server
```

### Create Pool Wallet:
Run the following to create a Pool Wallet name **Pool**, ensure you save the Wallet Address and Seed Phrase, then exit the Wallet CLI:
```
cd ~/pool
~/gntl/gntl-wallet-cli
```

#### Create Wallet Password File:
Open up wallet_pass for editing:
```
nano wallet_pass
```
Type in the password, then save and exit nano.

#### Restore Pool Wallet
It's good practice to restore the wallet to **test**, using your seed, to ensure that you've captured the seed phrase correctly, run the following to restore the wallet, and then exit the CLI:
```
~/gntl/gntl-wallet-cli --restore-deterministic-wallet
```

Once you've confirmed the Wallet Address matches the once you captured earlier, you can delete the wallet by running:
```
rm test
rm test.keys
```

### Configure Caddy:
Open up Caddyfile for editing:
```
sudo nano /etc/caddy/Caddyfile
```
Change **POOL_URL** to your actual URL, then save and exit nano.

Load the changes, by running:
```
sudo systemctl reload caddy
```

### Link Certificates:
We need to create a symbolic link to our certificates, rather than copying them, so when they renew, we don't have to worry about updating the copy.  Grant permissions to the ceriticate folder, by running:
```
sudo chmod -R +rx /var/lib/caddy
```

Run the following (changing **POOL_URL** to your actual URL):
```
sudo ln -s /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/POOL_URL/POOL_URL.crt cert.pem
sudo ln -s /var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/POOL_URL/POOL_URL.key cert.key
```

### Config JSON Changes:
Open up config.json for editing:
```
nano config.json
```

Change the following to you personal values, then save and exit nano:
```
"poolHost": "POOL_URL",
"poolAddress": "POOL_WALLET",
"password": "Password1234",
```

### Config JS Changes:
Open up config.js for editing:
```
nano website/config.js
```

Change the following to you personal values, then save and exit nano:
```
var api = "https://POOL_URL/api";
var poolHost = "POOL_URL";
var email = "support@poolhost.com";
var telegram = "https://t.me/YourPool";
var discord = "https://discordapp.com/invite/YourPool";
```

### Create Processes
We'll now create our Wallet and Pool processes in Node Process Manager, and save the processes, and finally set them to auto-start on boot, by running:
```
pm2 start /home/gntlpool/gntl/gntl-wallet-rpc -- --rpc-bind-port 16669 --password-file wallet_pass --wallet-file Pool --disable-rpc-login --trusted-daemon
pm2 start init.js --name=Pool --log-date-format="YYYY-MM-DD HH:mm Z"
cd ~
pm2 save
pm2 startup
```
**NOTE: Run the output command provided by the `pm2 startup` command.  If the pm2 command is not found, run `source ~/.bashrc` then try again.**

## Additional Information
### Back End Parameters
Explanation for each field:
```javascript
/* Pool host displayed in notifications and front-end */
"poolHost": "POOL_URL",

/* Used for storage in redis so multiple coins can share the same redis instance. */
"coin": "GNTLCoin", // Must match the parentCoin variable in config.js

/* Used for front-end display */
"symbol": "GNTL",

/* Minimum units in a single coin, see COIN constant in DAEMON_CODE/src/cryptonote_config.h */
"coinUnits": 1000000000,

/* Number of coin decimals places for notifications and front-end */
"coinDecimalPlaces": 9,
  
/* Coin network time to mine one block, see DIFFICULTY_TARGET constant in DAEMON_CODE/src/cryptonote_config.h */
"coinDifficultyTarget": 120,

"blockchainExplorer": "https://explorer.gntl.cash/block/{id}",  //used on blocks page to generate hyperlinks.
"transactionExplorer": "https://explorer.gntl.cash/tx/{id}",    //used on the payments page to generate hyperlinks

/* Set daemon type. Supported values: default, forknote (Fix block height + 1), bytecoin (ByteCoin Wallet RPC API) */
"daemonType": "default",

/* Set Cryptonight algorithm settings.
"cnAlgorithm": "randomx",
"cnVariant": 2,
"cnBlobType": 0,
"includeHeight": true, /*true to include block.height in job to miner*/
"includeAlgo":"rx/arq", /*GNTL specific change to include algo in job to miner*/	
"isRandomX": true,
/* Logging */
"logging": {

    "files": {

        /* Specifies the level of log output verbosity. This level and anything
           more severe will be logged. Options are: info, warn, or error. */
        "level": "info",

        /* Directory where to write log files. */
        "directory": "logs",

        /* How often (in seconds) to append/flush data to the log files. */
        "flushInterval": 5
    },

    "console": {
        "level": "info",
        /* Gives console output useful colors. If you direct that output to a log file
           then disable this feature to avoid nasty characters in the file. */
        "colors": true
    }
},
/* Modular Pool Server */
"poolServer": {
    "enabled": true,
    "mergedMining":false,
    /* Set to "auto" by default which will spawn one process/fork/worker for each CPU
       core in your system. Each of these workers will run a separate instance of your
       pool(s), and the kernel will load balance miners using these forks. Optionally,
       the 'forks' field can be a number for how many forks will be spawned. */
    "clusterForks": "auto",

    /* Address where block rewards go, and miner payments come from. */
    "poolAddress": "POOL_WALLET",
    
    /* This is the Public address prefix used for miner login validation. */
    "pubAddressPrefix": 0x7b2ed,
    
    /* This is the Integrated address prefix used for miner login validation. */
    "intAddressPrefix": 0x1c32ed,
    
    /* This is the Subaddress prefix used for miner login validation. */
    "subAddressPrefix": 0x20f2ed,
    
    /* Poll RPC daemons for new blocks every this many milliseconds. */
    "blockRefreshInterval": 1000,

    /* How many seconds until we consider a miner disconnected. */
    "minerTimeout": 900,

    "sslCert": "./cert.pem", // The SSL certificate
    "sslKey": "./cert.key", // The SSL private key
    "sslCA": "./cert.pem" // The SSL certificate authority chain
    
    "ports": [
        {
            "port": 10007, // Port for mining apps to connect to
            "difficulty": 10000, // Initial difficulty miners are set to
            "desc": "Low starting difficulty (TLS)", // Description of port
            "ssl": true // TLS port
        },
        {
            "port": 20007,
            "difficulty": 100000,
            "desc": "Medium starting difficulty (TLS)",
            "ssl": true
        },
        {
            "port": 30007,
            "difficulty": 1000000,
            "desc": "High starting difficulty (TLS)",
            "ssl": true
        }
    ],

    /* Variable difficulty is a feature that will automatically adjust difficulty for
       individual miners based on their hashrate in order to lower networking and CPU
       overhead. */
    "varDiff": {
        "minDiff": 100, // Minimum difficulty
        "maxDiff": 5000000000000, // Maximum difficulty
        "targetTime": 60, // Try to get 1 share per this many seconds
        "retargetTime": 30, // Check to see if we should retarget every this many seconds
        "variancePercent": 30, // Allow time to vary this % from target without retargeting
        "maxJump": 100 // Limit diff percent increase/decrease in a single retargeting
    },
	
    /* Set payment ID on miner client side by passing <address>.<paymentID> */
    "paymentId": {
        "addressSeparator": ".", // Character separator between <address> and <paymentID>
        "validation": true // Refuse login if non alphanumeric characters in <paymentID>
        "validations": ["1,16", "64"], //regex quantity. range 1-16 characters OR exactly 64 character
        "ban": true  // ban the miner for invalid paymentid
    },

    /* Set difficulty on miner client side by passing <address> param with +<difficulty> postfix */
    "fixedDiff": {
        "enabled": true,
        "addressSeparator": ".", // Character separator between <address> and <difficulty>
    },

    /* Feature to trust share difficulties from miners which can
       significantly reduce CPU load. */
    "shareTrust": {
        "enabled": true,
        "min": 10, // Minimum percent probability for share hashing
        "stepDown": 3, // Increase trust probability % this much with each valid share
        "threshold": 10, // Amount of valid shares required before trusting begins
        "penalty": 30 // Upon breaking trust require this many valid share before trusting
    },

    /* If under low-diff share attack we can ban their IP to reduce system/network load. */
    "banning": {
        "enabled": true,
        "time": 600, // How many seconds to ban worker for
        "invalidPercent": 25, // What percent of invalid shares triggers ban
        "checkThreshold": 30 // Perform check when this many shares have been submitted
    },
    
    /* Slush Mining is a reward calculation technique which disincentivizes pool hopping and rewards 'loyal' miners by valuing younger shares higher than older shares. Remember adjusting the weight!
    More about it here: https://mining.bitcoin.cz/help/#!/manual/rewards */
    "slushMining": {
        "enabled": false, // Enables slush mining. Recommended for pools catering to professional miners
        "weight": 300 // Defines how fast the score assigned to a share declines in time. The value should roughly be equivalent to the average round duration in seconds divided by 8. When deviating by too much numbers may get too high for JS.
    }
},

/* Module that sends payments to miners according to their submitted shares. */
"payments": {
    "enabled": true,
    "interval": 600, // How often to run in seconds
    "maxAddresses": 15, // Split up payments if sending to more than this many addresses
    "mixin": 10, // Number of transactions yours is indistinguishable from
    "priority": 0, // The transaction priority    
    "transferFee": 100000, // Fee to pay for each transaction
    "dynamicTransferFee": true, // Enable dynamic transfer fee (fee is multiplied by number of miners)
    "minerPayFee" : true, // Miner pays the transfer fee instead of pool owner when using dynamic transfer fee
    "minPayment": 10000000000, // Miner balance required before sending payment
    "maxPayment": 750000000000, // Maximum miner balance allowed in miner settings
    "maxTransactionAmount": 1500000000000, // Split transactions by this amount (to prevent "too big transaction" error)
    "denomination": 100000000 // Truncate to this precision and store remainder
},

/* Module that monitors the submitted block maturities and manages rounds. Confirmed
   blocks mark the end of a round where workers' balances are increased in proportion
   to their shares. */
"blockUnlocker": {
    "enabled": true,
    "interval": 30, // How often to check block statuses in seconds

    /* Block depth required for a block to unlocked/mature. Found in daemon source as
       the variable CRYPTONOTE_MINED_MONEY_UNLOCK_WINDOW */
    "depth": 18,
    "poolFee": 0.3, // 0.3% pool fee (1% total fee total including donations)
    "soloFee": 1, // solo fee
    "finderReward": 0.2, // 0.2 finder reward
    "devDonation": 0, // 0% donation to send to pool dev
    "networkFee": 0, // Network/Governance fee (used by some coins like Loki)
    
    /* Some forknote coins have an issue with block height in RPC request, to fix you can enable this option.
       See: https://github.com/forknote/forknote-pool/issues/48 */
    "fixBlockHeightRPC": false
},

/* AJAX API used for front-end website. */
"api": {
    "enabled": true,
    "hashrateWindow": 600, // How many second worth of shares used to estimate hash rate
    "updateInterval": 3, // Gather stats and broadcast every this many seconds
    "bindIp": "0.0.0.0", // Bind API to a specific IP (set to 0.0.0.0 for all)
    "port": 8117, // The API port
    "blocks": 30, // Amount of blocks to send at a time
    "payments": 30, // Amount of payments to send at a time
    "password": "Password1234", // Password required for admin stats
    "ssl": false, // Enable SSL API
    "sslPort": 8119, // The SSL port
    "sslCert": "./cert.pem", // The SSL certificate
    "sslKey": "./privkey.pem", // The SSL private key
    "sslCA": "./chain.pem", // The SSL certificate authority chain
    "trustProxyIP": true // Proxy X-Forwarded-For support
},

/* Coin daemon connection details (default port is 16662) */
"daemon": {
    "host": "127.0.0.1",
    "port": 16662
},

/* Wallet daemon connection details (default port is 16669) */
"wallet": {
    "host": "127.0.0.1",
    "port": 16669,
    "password": "--rpc-password"
},

/* Redis connection info (default port is 6379) */
"redis": {
    "host": "127.0.0.1",
    "port": 6379,
    "auth": null, // If set, client will run redis auth command on connect. Use for remote db
    "db": 0, // Set the REDIS database to use (default to 0)
    "cleanupInterval": 90 // Set the REDIS database cleanup interval (in days)
}

/* Pool Notifications */
"notifications": {
    "emailTemplate": "email_templates/default.txt",
    "emailSubject": {
        "emailAdded": "Your email was registered",
        "workerConnected": "Worker %WORKER_NAME% connected",
        "workerTimeout": "Worker %WORKER_NAME% stopped hashing",
        "workerBanned": "Worker %WORKER_NAME% banned",
        "blockFound": "Block %HEIGHT% found !",
        "blockUnlocked": "Block %HEIGHT% unlocked !",
        "blockOrphaned": "Block %HEIGHT% orphaned !",
        "payment": "We sent you a payment !"
    },
    "emailMessage": {
        "emailAdded": "Your email has been registered to receive pool notifications.",
        "workerConnected": "Your worker %WORKER_NAME% for address %MINER% is now connected from ip %IP%.",
        "workerTimeout": "Your worker %WORKER_NAME% for address %MINER% has stopped submitting hashes on %LAST_HASH%.",
        "workerBanned": "Your worker %WORKER_NAME% for address %MINER% has been banned.",
        "blockFound": "Block found at height %HEIGHT% by miner %MINER% on %TIME%. Waiting maturity.",
        "blockUnlocked": "Block mined at height %HEIGHT% with %REWARD% and %EFFORT% effort on %TIME%.",
        "blockOrphaned": "Block orphaned at height %HEIGHT% :(",
        "payment": "A payment of %AMOUNT% has been sent to %ADDRESS% wallet."
    },
    "telegramMessage": {
        "workerConnected": "Your worker _%WORKER_NAME%_ for address _%MINER%_ is now connected from ip _%IP%_.",
        "workerTimeout": "Your worker _%WORKER_NAME%_ for address _%MINER%_ has stopped submitting hashes on _%LAST_HASH%_.",
        "workerBanned": "Your worker _%WORKER_NAME%_ for address _%MINER%_ has been banned.",
        "blockFound": "*Block found at height* _%HEIGHT%_ *by miner* _%MINER%_*! Waiting maturity.*",
        "blockUnlocked": "*Block mined at height* _%HEIGHT%_ *with* _%REWARD%_ *and* _%EFFORT%_ *effort on* _%TIME%_*.*",
        "blockOrphaned": "*Block orphaned at height* _%HEIGHT%_ *:(*",
        "payment": "A payment of _%AMOUNT%_ has been sent."
    }
},

/* Email Notifications */
"email": {
    "enabled": false,
    "fromAddress": "your@email.com", // Your sender email
    "transport": "sendmail", // The transport mode (sendmail, smtp or mailgun)
    
    // Configuration for sendmail transport
    // Documentation: http://nodemailer.com/transports/sendmail/
    "sendmail": {
        "path": "/usr/sbin/sendmail" // The path to sendmail command
    },
    
    // Configuration for SMTP transport
    // Documentation: http://nodemailer.com/smtp/
    "smtp": {
        "host": "smtp.example.com", // SMTP server
        "port": 587, // SMTP port (25, 587 or 465)
        "secure": false, // TLS (if false will upgrade with STARTTLS)
        "auth": {
            "user": "username", // SMTP username
            "pass": "password" // SMTP password
        },
        "tls": {
            "rejectUnauthorized": false // Reject unauthorized TLS/SSL certificate
        }
    },
    
    // Configuration for MailGun transport
    "mailgun": {
        "key": "your-private-key", // Your MailGun Private API key
        "domain": "mg.yourdomain" // Your MailGun domain
    }
},

/* Telegram channel notifications.
   See Telegram documentation to setup your bot: https://core.telegram.org/bots#3-how-do-i-create-a-bot */
"telegram": {
    "enabled": false,
    "botName": "", // The bot user name.
    "token": "", // The bot unique authorization token
    "channel": "", // The telegram channel id (ex: BlockHashMining)
    "channelStats": {
        "enabled": false, // Enable periodical updater of pool statistics in telegram channel
        "interval": 5 // Periodical update interval (in minutes)
    },
    "botCommands": { // Set the telegram bot commands
        "stats": "/stats", // Pool statistics
         "enable": "/enable", // Enable telegram notifications
        "disable": "/disable" // Disable telegram notifications
    }    
},

/* Monitoring RPC services. Statistics will be displayed in Admin panel */
"monitoring": {
    "daemon": {
        "checkInterval": 60, // Interval of sending rpcMethod request
        "rpcMethod": "getblockcount" // RPC method name
    },
    "wallet": {
        "checkInterval": 60,
        "rpcMethod": "getbalance"
    }
},

/* Prices settings for market and price charts */
"prices": {
    "source": "cryptonator", // Exchange (supported values: cryptonator, altex, crex24, cryptopia, stocks.exchange, tradeogre, maplechange)
    "currency": "USD" // Default currency
},
	    
/* Collect pool statistics to display in frontend charts  */
"charts": {
    "pool": {
        "hashrate": {
            "enabled": true, // Enable data collection and chart displaying in frontend
            "updateInterval": 60, // How often to get current value
            "stepInterval": 1800, // Chart step interval calculated as average of all updated values
            "maximumPeriod": 86400 // Chart maximum periods (chart points number = maximumPeriod / stepInterval = 48)
        },
        "miners": {
            "enabled": true,
            "updateInterval": 60,
            "stepInterval": 1800,
            "maximumPeriod": 86400
        },
        "workers": {
            "enabled": true,
            "updateInterval": 60,
            "stepInterval": 1800,
            "maximumPeriod": 86400
        },
        "difficulty": {
            "enabled": true,
            "updateInterval": 1800,
            "stepInterval": 10800,
            "maximumPeriod": 604800
        },
        "price": {
            "enabled": true,
            "updateInterval": 1800,
            "stepInterval": 10800,
            "maximumPeriod": 604800
        },
        "profit": {
            "enabled": true,
            "updateInterval": 1800,
            "stepInterval": 10800,
            "maximumPeriod": 604800
        }

    },
    "user": { // Chart data displayed in user stats block
        "hashrate": {
            "enabled": true,
            "updateInterval": 180,
            "stepInterval": 1800,
            "maximumPeriod": 86400
        },
        "worker_hashrate": {
            "enabled": true,
            "updateInterval": 60,
            "stepInterval": 60,
            "maximumPeriod": 86400
        },
        "payments": { // Payment chart uses all user payments data stored in DB
            "enabled": true
        }
    },
    "blocks": {
        "enabled": true,
        "days": 30 // Number of days displayed in chart (if value is 1, display last 24 hours)
    }
}
```

This software contains several distinct modules:
* `daemon` - Which opens communications to the coin daemon
* `pool` - Which opens ports for miners to connect and processes shares
* `api` - Used by the website to display network, pool and miners' data
* `unlocker` - Processes block candidates and increases miners' balances when blocks are unlocked
* `payments` - Sends out payments to miners according to their balances stored in redis
* `chartsDataCollector` - Processes miners and workers hashrate stats and charts
* `telegramBot`	- Processes telegram bot commands


By default, running the `init.js` script will start up all modules. You can optionally have the script start
only start a specific module by using the `-module=name` command argument, for example:

```bash
node init.js -module=api
```

### Front End Parameters
Edit the variables in the `pool/website/config.js` file to use your pool's specific configuration.
Variable explanations:

```javascript

/* Merged Mining parent coin */
var parentCoin = "GNTLCoin";

/* Must point to the API setup in your config.json file. */
var api = "https://POOL_URL/api";

/* Pool server host to instruct your miners to point to (override daemon setting if set) */
var poolHost = "POOL_URL";

/* Contact email address. */
var email = "support@poolhost.com";

/* Pool Telegram URL. */
var telegram = "https://t.me/YourPool";

/* Pool Discord URL */
var discord = "https://discordapp.com/invite/YourPool";

/*Pool Facebook URL */
var facebook = "https://www.facebook.com/<YourPoolFacebook";

/* Market stat display params from https://www.cryptonator.com/widget */
var marketCurrencies = ["{symbol}-BTC", "{symbol}-USD", "{symbol}-EUR", "{symbol}-CAD"];

/* Used for front-end block links. */
var blockchainExplorer = "https://explorer.gntl.cash/block/{id}";

/* Used by front-end transaction links. */
var transactionExplorer = "https://explorer.gntl.cash/tx/{id}";

/* Any custom CSS theme for pool frontend */
var themeCss = "themes/light.css";

/* Default language */
var defaultLang = 'en';

```

The following files are included so that you can customize your pool website without having to make significant changes
to `index.html` or other front-end files thus reducing the difficulty of merging updates with your own changes:
* `custom.css` for creating your own pool style
* `custom.js` for changing the functionality of your pool website

### Upgrading
When updating to the latest code its important to not only `git pull` the latest from this repo, but to also update
the Node.js modules, and any config files that may have been changed.
* Inside your pool directory (where the init.js script is) do `git pull` to get the latest code.
* Remove the dependencies by deleting the `node_modules` directory with `rm -r node_modules`.
* Run `npm update` to force updating/reinstalling of the dependencies.
* Compare your `config.json` to the latest example ones in this repo or the ones in the setup instructions where each config field is explained. You may need to modify or add any new changes.

## Features
### Optimized pool server
* TCP (stratum-like) protocol for server-push based jobs
  * Compared to old HTTP protocol, this has a higher hash rate, lower network/CPU server load, lower orphan
    block percent, and less error prone
* IP banning to prevent low-diff share attacks
* Socket flooding detection
* Share trust algorithm to reduce share validation hashing CPU load
* Clustering for vertical scaling
* Ability to configure multiple ports - each with their own difficulty
* Miner login (wallet address) validation
* Workers identification (specify worker name as the password)
* Variable difficulty / share limiter
* Set fixed difficulty on miner client by passing "address" param with "+[difficulty]" postfix
* Modular components for horizontal scaling (pool server, database, stats/API, payment processing, front-end)
* SSL support for both pool and API servers
* RBPPS (PROP) payment system

### Live statistics API
* Currency network/block difficulty
* Current block height
* Network hashrate
* Pool hashrate
* Each miners' individual stats (hashrate, shares submitted, pending balance, total paid, payout estimate, etc)
* Blocks found (pending, confirmed, and orphaned)
* Historic charts of pool's hashrate, miners count and coin difficulty
* Historic charts of users's hashrate and payments

### Mined blocks explorer
* Mined blocks table with block status (pending, confirmed, and orphaned)
* Blocks luck (shares/difficulty) statistics
* Universal blocks and transactions explorer based on [chainradar.com](http://chainradar.com)

### Smart payment processing
* Splintered transactions to deal with max transaction size
* Minimum payment threshold before balance will be paid out
* Minimum denomination for truncating payment amount precision to reduce size/complexity of block transactions
* Prevent "transaction is too big" error with "payments.maxTransactionAmount" option
* Option to enable dynamic transfer fee based on number of payees per transaction and option to have miner pay transfer fee instead of pool owner (applied to dynamic fee only)
* Control transactions priority with config.payments.priority (default: 0).
* Set payment ID on miner client when using "[address].[paymentID]" login
* Integrated payment ID addresses support for Exchanges

### Admin panel
* Aggregated pool statistics
* Coin daemon & wallet RPC services stability monitoring
* Log files data access
* Users list with detailed statistics

#### Pool stability monitoring
* Detailed logging in process console & log files
* Coin daemon & wallet RPC services stability monitoring
* See logs data from admin panel

### Extra features
* An easily extendable, responsive, light-weight front-end using API to display data
* Onishin's [keepalive function](https://github.com/perl5577/cpuminer-multi/commit/0c8aedb)
* Support for merged mining
* Support for slush mining system (disabled by default)
* E-Mail Notifications on worker connected, disconnected (timeout) or banned (support MailGun, SMTP and Sendmail)
* Telegram channel notifications when a block is unlocked
* Top 10 miners report
* Multilingual user interface

### JSON-RPC Commands from CLI
Documentation for JSON-RPC commands can be found here:
* Daemon https://wiki.bytecoin.org/wiki/JSON_RPC_API
* Wallet https://wiki.bytecoin.org/wiki/Wallet_JSON_RPC_API


Curl can be used to use the JSON-RPC commands from command-line. Here is an example of calling `getblockheaderbyheight` for block 100:

```bash
curl 127.0.0.1:18081/json_rpc -d '{"method":"getblockheaderbyheight","params":{"height":100}}'
```

### Monitoring Your Pool
* To inspect and make changes to redis I suggest using [redis-commander](https://github.com/joeferner/redis-commander)
* To monitor server load for CPU, Network, IO, etc - I suggest using [Netdata](https://github.com/firehol/netdata)
* `pm2 log` will show a live log of the Pool.


### Pools Using This Software
* https://gntldev.pool.gntl.co.uk/

### Donations
If you want to make a donation to [Dvandal](https://github.com/dvandal/), the developper of the original project, you can send any amount of your choice to one of theses addresses:

* Bitcoin (BTC): `392gS9zuYQBghmMpK3NipBTaQcooR9UoGy`
* Bitcoin Cash (BCH): `qp46fz7ht8xdhwepqzhk7ct3aa0ucypfgv5qvv57td`
* Monero (XMR): `49WyMy9Q351C59dT913ieEgqWjaN12dWM5aYqJxSTZCZZj1La5twZtC3DyfUsmVD3tj2Zud7m6kqTVDauRz53FqA9zphHaj`
* Dash (DASH): `XgFnxEu1ru7RTiM4uH1GWt2yseU1BVBqWL`
* Ethereum (ETH): `0x8c42D411545c9E1963ff56A91d06dEB8C4A9f444`
* Ethereum Classic (ETC): `0x4208D6775A2bbABe64C15d76e99FE5676F2768Fb`
* Litecoin (LTC): `LS9To9u2C95VPHKauRMEN5BLatC8C1k4F1`
* USD Coin (USDC): `0xb5c6BEc389252F24dd3899262AC0D2754B0fC1a3`
* Augur (REP): `0x5A66CE95ea2428BC5B2c7EeB7c96FC184258f064`
* Basic Attention Token (BAT): `0x5A66CE95ea2428BC5B2c7EeB7c96FC184258f064`
* Chainlink (LINK): `0x5A66CE95ea2428BC5B2c7EeB7c96FC184258f064`
* Dai (DAI): `0xF2a50BcCEE8BEb7807dA40609620e454465B40A1`
* Orchid (OXT): `0xf52488AAA1ab1b1EB659d6632415727108600BCb`
* Tezos (XTZ): `tz1T1idcT5hfyjfLHWeqbYvmrcYn5JgwrJKW`
* Zcash (ZCH): `t1YTGVoVbeCuTn3Pg9MPGrSqweFLPGTQ7on`
* 0x (ZRX): `0x4e52AAfC6dAb2b7812A0a7C24a6DF6FAab65Fc9a`

### Credits
* [fancoder](//github.com/fancoder) - Developper on cryptonote-universal-pool project from which current project is forked.
* [dvandal](//github.com/dvandal) - Developer of cryptonote-nodejs-pool software
* [The GNTL Project](//github.com/The-GNTL-Project) - Documentation updates and config corrections, mod for GNTL Coin

### License
Released under the GNU General Public License v2

http://www.gnu.org/licenses/gpl-2.0.html
