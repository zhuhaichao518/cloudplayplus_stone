@echo off

rem Stop and delete the legacy CloudPlayPlusSvc service
net stop cloudplayplussvc
sc delete cloudplayplussvc

rem Stop and delete the new CloudPlayPlusSvc service
net stop cloudplayplussvc
sc delete cloudplayplussvc
