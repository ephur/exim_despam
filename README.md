exim_despam
===========

A legacy perl script to clean up exim mail queues.

While working at a national ISP in the early 2000's we had a lot of customers who would create fraudulent accounts and use relay servers to send spam. We combatted the spam on our relays very agressively. This script started off a simple method to clean exim queues before there were better built in tools. It still works as of recent testing, and will allow you to parse through the mail queue even with hundreds of thousands of messages in the spool. It also keeps count, and can send an email to a defined contact if you want to do something about the abusers you find on your network. 

Putting this here for archival, and I still see somewhat recent questions (http://stackoverflow.com/questions/8508312/exim-mail-queue-is-full-of-spam) related to cleaning out exim mail queues, so maybe this will help someone. 

It's 10 years since the last update, maybe it will find new life! If I only I had a need to despam exim queues still :( 
