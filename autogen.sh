#! /bin/sh

# This file is part of OSSFS.
# 
# OSSFS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
# 
# OSSFS is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/. 
# 
#  See the file ChangeLog for a revision history. 

echo "--- Make commit hash file -------"

SHORTHASH="unknown"
type git > /dev/null 2>&1
if [ $? -eq 0 -a -d .git ]; then
	RESULT=`git rev-parse --short HEAD`
	if [ $? -eq 0 ]; then
		SHORTHASH=${RESULT}
	fi
fi
echo ${SHORTHASH} > default_commit_hash

echo "--- Finished commit hash file ---"

echo "--- Start autotools -------------"

aclocal \
&& autoheader \
&& automake --add-missing \
&& autoconf

echo "--- Finished autotools ----------"

exit 0

