package config

import "os"

func GetEnv(key, defaultValue string)string{
	if v, e := os.LookupEnv(key); e{
		return v
	}
	return defaultValue
}