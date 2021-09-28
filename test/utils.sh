set -e
# set -o pipefail

debug() {
	if [ "$Z" == "" ]; then
		>&2 echo "no zenroom executable configured"
		return 1
	fi
	if [ "$1" == "" ]; then
		>&2 echo "no script filename configured"
		return 1
	fi
	out="$1"
	shift 1
	>&2 echo "test: $out"
	tee "$out" | $Z -z $*
	return $?
}

zexe() {
	if [ "$DEBUG" == "1" ]; then
		debug $*
		return $?
	fi
	out="$1"
	shift 1
	echo >&2
	echo "====================================" >&2
	>&2 echo "== TEST: ${SUBDOC} $out"
	data=""
	keys=""
	for i in ${*}; do
		if [[ "$i" == "-a" ]]; then data=1; continue; fi
		if [[ $data == 1 ]]; then data="$i"; fi
		if [[ "$i" == "-k" ]]; then keys=1; continue; fi
		if [[ $keys == 1 ]]; then keys="$i"; fi
	done
	echo "data: $data" >&2
	echo "keys: $keys" >&2
	t=`mktemp -d`
	# >&2 echo $t
	        set +e
		tee "$out" | \
			lua5.1 -l zenroom ../ztest.lua "$data $keys" 2>$t/stderr 1>$t/stdout
	res=$?
	set -e
        if [ $res == 0 ]; then
                cat $t/stdout
        else
                >&2 cat $t/stderr
                exit 1
        fi
	>&2 echo "exitcode: $res"
	rm -rf "$t"
	return $res
}

save() {
	here="./"
	>&2 echo "output: $2"
	if [[ "${2##*.}" == "json" ]]; then
		if command -v jq > /dev/null; then
			tee ${here}/"$2" | jq .
		fi
	else
		tee ${here}/"$2"
	fi
	>&2 echo "===================================="
}

success() {
	p=`pwd`
	echo
	echo "####################################"
	echo "SUCCESS: `basename $p`"
	echo "####################################"
	echo
	echo
}

# example:
# json_extract "Alice" petition_request.json > petition_keypair.json
function json_extract {
	if ! [ -r extract.jq ]; then
		cat <<EOF > extract.jq
# break out early
def filter(\$key):
  label \$out
  | foreach inputs as \$in ( null;
      if . == null
      then if \$in[0][0] == \$key then \$in
           else empty
           end
      elif \$in[0][0] != \$key then break \$out
      else \$in
      end;
      select(length==2) );
reduce filter(\$key) as \$in ({};
  setpath(\$in[0]; \$in[1]) )
EOF
	fi
	jq -n -c --arg key "$1" --stream -f extract.jq "$2"
}

# example:
# json_remove "Alice" petition_request.json
function json_remove {
	tmp=`mktemp`
	jq -M "del(.$1)" $2 > $tmp
	mv $tmp $2
	rm -f $tmp
}

function json_join {
	jq -s 'reduce .[] as $item ({}; . * $item)' $*
}


# # requires luajit and cjson
# # example:
# # json_join left.json right.json
# function json_join {
# 	tmp=`mktemp`
# 	cat <<EOF > $tmp
# J = require "cjson"
# local fd
# fd = io.open('$1',"r")
# left = fd:read '*all'
# fd:close()
# fd = io.open('$2',"r")
# right = fd:read '*all'
# fd:close()
# local r = { }
# for k,v in pairs( J.decode( left ) ) do
# 	r[k] = v
# end
# for k,v in pairs( J.decode( right) ) do
# 	r[k] = v
# end
# print(J.encode(r))
# EOF
# 	luajit $tmp
# 	rm -f $tmp
# }
