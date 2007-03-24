// userinfo.h

#pragma once

#include <string>
#include <map>
#include <iostream>

class Info {
	std::map <std::string,std::string> keys;
	int _len;
	int _maxsize;
public:
	Info (int maxsize = 0): _len(0), _maxsize(maxsize) {};
	void clear () { keys.clear(); _len = 0; };
	void init (int maxsize = 0) { clear(); _maxsize = maxsize; };
	size_t length() { return _len; };
	const std::string operator[] (std::string key);	// read only
	bool set (std::string key, std::string value);
	void remove_prefixed_keys (char prefix);
	std::string to_string ();
	void print ();
	void load_from_string (std::string s);
	Info& operator= (Info i) { keys = i.keys; _len = i._len; return *this; };
};
