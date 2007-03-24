// userinfo.cpp : Defines the entry point for the console application.
//

#include "info.h"
#include "common.h"		// Com_Printf

using namespace std;

bool Info::set (string key, string value) {
	if (key.find('\0') != string::npos || value.find('\0') != string::npos) {
		assert (!"key or value with a \0");
		return false;
	}

	if (key.find('\"') != string::npos || value.find('\"') != string::npos) {
		Com_Printf ("Can't use keys or values with a \"\n");
		return false;
	}

	if (key.find('\\') != string::npos || value.find('\\') != string::npos) {
		Com_Printf ("Can't use keys or values with a \\\n");
		return false;
	}

	size_t oldlen = keys[key].length();
	size_t newl = value.length();
	if (newl) {
		int newtotallen;
		if (oldlen) {
			newtotallen = _len + value.length() - oldlen;
		} else {
			newtotallen = _len + value.length() + key.length() + 2 /* two separators */;
		}
		if (_maxsize && newtotallen > _maxsize) {
			Com_Printf ("Info string length exceeded\n");
			return false;
		}
		keys[key] = value;
		_len = newtotallen;
	}
	else {
		keys.erase(key);
		_len -= oldlen + key.length() + 2;
	}

	return true;
}

void Info::remove_prefixed_keys(char prefix) {
restart:
	for (map<string,string>::iterator i = keys.begin(); i != keys.end(); i++)
		if (i->first[0] == prefix) {
			set(i->first, "");
			goto restart;
		}
}

const string Info::operator[] (string key)
{
	map<string,string>::iterator i = keys.find(key);
	if (i != keys.end())
		return i->second;
	else
		return "";
}

void Info::print() {
	map<string,string>::iterator i;
	for (i = keys.begin(); i != keys.end(); i++)
		Com_Printf ("%-19s %s\n", i->first.c_str(), i->second.c_str());
}

string Info::to_string () {
	string s;
	for (map<string,string>::iterator i = keys.begin(); i != keys.end(); i++) {
		s += '\\' + i->first + '\\' + i->second;
	}
	return s;
}

void Info::load_from_string (string ss) {
	this->clear();

	const char *s = ss.c_str();

	if (*s == '\\')
		s++;
	while (*s) {
		string key, value;

		while (*s && *s != '\\')
			key += *s++;

		if (!*s) {
			// missing value
			break;
		}

		s++;
		while (*s && *s != '\\')
			value += *s++;

		if (*s)
			s++;

		set(key, value);
	}
}
