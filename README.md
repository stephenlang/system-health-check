## system-health-check

Server monitoring for Memory, swap, process monitoring, storage check,
and more.


### Purpose

Without an agent based monitoring system, monitoring your servers internals
for items such as CPU, memory, storage, processes, etc becomes very
difficult without manually checking.  There are many reputable monitoring
services on the web such as Pingdom (www.pingdom.com),  and most hosting
providers provide a monitoring system, but they do not provide an agent.
Therefore, you can only do basic external checks such as ping, port, and
http content checks.  There is no way to report if your MySQL replication
has failed, some critical process has stopped running, or if your about to
max out your / partition.

This simple bash script is meant to compliment these types of monitoring
services.  Just drop the script into a web accessible directory, configure
a few options and thresholds, setup a URL content check that looks at the
status page searching for the string 'OK', and then you can rest easy at
night that your monitoring service will alert you if any of the scripts
conditions are triggered.

Security note:  To avoid revealing information about your system, it is
strongly recommended that you place this and all web based monitoring
scripts behind a htaccess file that has authentication, whitelisting your
monitoring servers IP addresses if they are known.


### Features
- Memory Check
- Swap Check
- Load Check
- Storage Check
- Process Check
- Replication Check


### Configuration

The currently configurable options and thresholds are listed below:

	# Status page
	status_page=/var/www/system-health-check.html

	# Enable / Disable Checks
	memory_check=off
	swap_check=on
	load_check=on
	storage_check=on
	process_check=on
	replication_check=off

	# Configure partitions for storage check
	partitions=( / )

	# Configure process(es) to check
	process_names=( httpd mysqld postfix )

	# Configure Thresholds
	memory_threshold=99
	swap_threshold=80
	load_threshold=10
	storage_threshold=80


### Implementation

Download script to desired directory and set it to be executable:

	cd /root
	git clone https://github.com/stephenlang/system-health-check
	chmod 755 system-health-check/system-health-check.sh

After configuring the tunables in the script (see above), create a cron
job to execute the script every 5 minutes:
	
	crontab -e
	*/5 * * * * /root/system-health-check/system-health-check.sh

Now configure a URL content check with your monitoring providers tools
check the status page searching for the string "OK".  Below are two
examples:

	http://1.1.1.1/system-health-check.html
	http://www.example.com/system-health-check.html


### Testing

It is critical that you test this monitoring script before you rely on it.
Bugs always exist somewhere, so test this before you implement it on your
production systems!  Here are some basic ways to test:

1.  Configure all the thresholds really low so they will create an alarm.
Manually run the script or wait for the cronjob to fire it off, then check
the status page to see if it reports your checks are now in alarm.

2.  To test out the process monitoring (assuming the system is not in
production), configure the processes you want the script to check, then
stop the process you are testing, and check the status page after the
script runs to see if it reports your process is not running.

3.  To test out the replication monitoring (assuming the system is not in
production), log onto your MySQL slave server and run 'stop slave;'.  Then
check the status page after the script runs to see if it reports an error
on replication.
