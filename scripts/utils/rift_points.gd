class_name RiftPoints
extends RefCounted
## Player-facing wording for Rift Points, the only currency: `1,250 RP` after numbers.
##
## GDD §6 and ADR-0013 name the currency; spec 01 fixes the text rule: the short form `RP` follows a
## number, the long form "Rift Points" is used in sentences. Screens format through here so the rule
## lives in one place. The shard icon stays next to the value.

## Short unit shown after a number.
const UNIT: String = "RP"
## Long name used in sentences.
const NAME: String = "Rift Points"


## Groups thousands with commas ("12,480"); negative values keep their sign.
static func group_digits(value: int) -> String:
	var digits: String = str(absi(value))
	var grouped: String = ""
	while digits.length() > 3:
		grouped = "," + digits.right(3) + grouped
		digits = digits.left(digits.length() - 3)
	return ("-" if value < 0 else "") + digits + grouped


## A balance or price: "1,250 RP".
static func format(amount: int) -> String:
	return "%s %s" % [group_digits(amount), UNIT]


## A reward or gain: "+45 RP".
static func format_gain(amount: int) -> String:
	return "+%s %s" % [group_digits(maxi(0, amount)), UNIT]
