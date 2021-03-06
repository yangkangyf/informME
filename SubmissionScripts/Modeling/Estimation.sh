#!/bin/bash
#
# informME: An information-theoretic pipeline for WGBS data
# Copyright (C) 2017, Garrett Jenkinson (jenkinson@jhu.edu)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
# or see <http://www.gnu.org/licenses/>.

# Estimation.sh

# last modified 12/09/16

# Shell script to run function Estimation.m in MATLAB

# get inputs
bamFileNames=$1
chr_num=$2
phenoName=$3
species=$4
totalProcessors=$5
processorNum=$6
MATLICE=$7

echo "starting command: EstParamsForChr(${bamFileNames},${chr_num},'${phenoName}','species','${species}','totalProcessors',${totalProcessors},'processorNum',${processorNum});"

# Run MATLAB command
matlab -nodesktop -singleCompThread -nosplash -nodisplay -c ${MATLICE} -r "disp('Job Running');tic;EstParamsForChr(${bamFileNames},${chr_num},'${phenoName}','species','${species}','totalProcessors',${totalProcessors},'processorNum',${processorNum});toc;"

# Check if error in MATLAB, otherwise declare success
EXITCODE=$?
if [ $EXITCODE -ne 0 ]
then
   echo "error in MATLAB"
   echo "tic;EstParamsForChr(${bamFileNames},${chr_num},'${phenoName}','species','${species}','totalProcessors',${totalProcessors},'processorNum',${processorNum});toc;"
   exit $EXITCODE
fi

echo "command successful:"
echo "tic;EstParamsForChr(${bamFileNames},${chr_num},'${phenoName}','species','${species}','totalProcessors',${totalProcessors},'processorNum',${processorNum});toc;"
