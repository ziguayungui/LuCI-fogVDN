#! /usr/bin/awk -f
#  
# write by fuqiyang awk  
#
#

BEGIN {
	FS=" ";
	"date +%Y" | getline YEAR
	"date +%m" | getline MONTH
	"date +%d" | getline DAY
	"date +%H" | getline HOUR
	"date +%M" | getline MINUTE
	"date +%S" | getline SECOND

	if(MINUTE > 5) {
		MINUTE=MINUTE-5;
		if (MINUTE < 10) { MINUTE="0"MINUTE; }
	} else {
		MINUTE=MINUTE+55;
		if (HOUR > 1) {
			HOUR=HOUR-1;
			if (HOUR < 10) { HOUR="0"HOUR; }
		} else { HOUR=HOUR+23; }
	}
	start_time=(YEAR"-"MONTH"-"DAY"T"HOUR":"MINUTE":"SECOND)
	###printf "start_time: %s\n",start_time
	printf "traffic "
}
	
{
	if($3 >= start_time && (($7 == "200") || ($7 == "206"))){
		split($5, host, "/");
		sum[host[2]] += $8;
	}
}

END {
	for (i in sum) {
		printf "%s %s ", i, sum[i]
	}

	#print "{\"host\":\""i"\",\"traffic\":\""sum[i]"\"}";
}

