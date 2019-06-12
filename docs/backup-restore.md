# Partial restoration

This is necessary if you lost a specific email, or if you want to go back in time, and restore a bunch of emails you
inadvertently deleted.

At this time, the partial restoration is manual and can be done only by root. An easier option to retrieve emails from
backups will be provided in a future version. In the mean time, the process has to be manual:

1. Connect on the server, using SSH, as root.
2. Load the backup encryption key into your environment.
3. List the backups snapshots, using [borg list command](https://borgbackup.readthedocs.io/en/stable/usage/list.html)
4. Mount the backup snapshot you are interested in, they are listed by date.
   You can do this by using the [borg mount command](https://borgbackup.readthedocs.io/en/stable/usage/mount.html)
5. Search in the mounted drive for the lost emails, using for instance the excellent midnight commander.
6. Copy the emails at the place of your choice, perhaps in your /home/users/<user>/mails/maildir/ folder to make them
   accessible from an email client.
7. Make sure the copied email files belongs to the right user, otherwise Dovecot won't be able to read these files.
   belongs to the right user.
8. The last thing to do, before disconnecting, is to ‘unmount’ the backup snapshot, using the
   [borg umount command](https://borgbackup.readthedocs.io/en/stable/usage/mount.html#borg-umount)
9. Finally, disconnect from SSH.
10. Open your email client.

# Complete restoration

OK, something bad happened, and you lost your box. Don't panic, if you have installed the system properly, you can
easily restore it from scratch, with the all emails as well. This is done by adding one line in your sysetm.yml file!

The important thing is to have kept the [deployment backup folder](deployment-backup.md) in a safe place, for instance
on an encrypted USB drive.

Let's say you have used Amazon S3 for the daily backup of your system. So, open your system.yml file with your favourite
editor, and add the line `restore: true` to the backup location you want to restore from. For instance:

```yaml

#############################################################################
# Example backup settings
backup:
  install: true
  alerts:
    from: 'postmaster@casimir.fx'
    recipient: 'hendrick@universiteitleiden.nl'
    jabber: true
  locations:
  - name: s3main
  → restore: true
    url: s3fs://mnt/backup/s3main/casimir.fx
    active: yes
    frequency: daily
    keep_daily: 7
    keep_weekly: 4
    keep_monthly: 6
    access_key_id: AKIAM2HEGKRL50SDZTTC
    secret_access_key: MpHag/11PUXRVIDSKMV8YQZZDW95IGDV
    bucket_name: casimir.fx
    region: eu-west-2
    check_frequency: weekly
```

Now, run the main installation script, to completely reinstall the system. For instance:

```sh
cd install
ansible-playbook -v -i ../config/hosts.yml playbooks/main.yml
```

The whole installation is taking enough time for you to have a well deserved break. Prepare yourself a nice cup of tea
or coffee. Once installed, you should have all your emails from the last backup restored.

In this example, an email and a Jabber message is sent after the system has been restored.
