<html lang="en">
<!-- Author: Dmitri Popov, dmpop@linux.com
         License: GPLv3 https://www.gnu.org/licenses/gpl-3.0.txt -->

<head>
	<title>Little Backup Box</title>
	<meta charset="utf-8">
	<link rel="shortcut icon" href="favicon.png" />
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<link rel="stylesheet" href="css/uikit.min.css" />
	<script src="js/uikit.min.js"></script>
	<script src="js/uikit-icons.min.js"></script>
	<style>
		.uk-button {
			width: 14em;
		}
	</style>
</head>

<body>
	<?php
	// include i18n class and initialize it
	require_once 'i18n.class.php';
	$i18n = new i18n('lang/{LANGUAGE}.ini', 'cache/', 'en');
	$i18n->init();
	?>
	<div class="uk-container uk-margin-small-top">
		<div class="uk-card uk-card-primary uk-card-body uk-text-center">
			<h1 class="uk-heading-line uk-text-center"><span>LITTLE BACKUP BOX</span></h1>
			<a class="uk-button uk-button-default uk-margin-small-top" href="sysinfo.php"><?php echo L::sysinfo; ?></a>
			<a class="uk-button uk-button-default uk-margin-small-top" href="raw-viewer/"><?php echo L::viewer; ?></a>
			<a class="uk-button uk-button-default uk-margin-small-top" href="config.php"><?php echo L::config; ?></a>
		</div>
		<div class="uk-card uk-card-default uk-card-body uk-text-center">
			<form method="post">
				<button class="uk-button uk-button-primary uk-margin-small-top" name="cardbackup"><?php echo L::cardbackup_b; ?></button>
				<button class="uk-button uk-button-primary uk-margin-small-top" name="camerabackup"><?php echo L::camerabackup_b; ?></button>
				<button class="uk-button uk-button-primary uk-margin-small-top" name="internalbackup"><?php echo L::internalbackup_b; ?></button>
			</form>
		</div>
		<div class="uk-card uk-card-default uk-card-body uk-text-center">
			<form method="post">
				<button class="uk-button uk-button-danger uk-margin-small-top" name="shutdown"><?php echo L::shutdown_b; ?></button>
			</form>
			<button class="uk-button uk-button-default" type="button" uk-toggle="target: #modal-example"><?php echo L::help; ?></button>
			<div id="modal-example" uk-modal>
				<div class="uk-modal-dialog uk-modal-body">
					<h2 class="uk-modal-title"><?php echo L::help; ?></h2>
					<p><?php echo L::help_txt; ?></p>
					<p class="uk-text-right">
						<button class="uk-button uk-button-primary uk-modal-close" type="button"><?php echo L::back_b; ?></button>
					</p>
				</div>
			</div>
		</div>
		<?php
		if (isset($_POST['cardbackup'])) {
			shell_exec('sudo pkill -f card-backup*');
			shell_exec('sudo umount /media/storage');
			shell_exec('sudo ./card-backup.sh > /dev/null 2>&1 & echo $!');
			echo "<script>";
			echo "UIkit.notification({message: '" . L::cardbackup_m . "', status: 'success'});";
			echo "</script>";
		}
		if (isset($_POST['camerabackup'])) {
			shell_exec('sudo pkill -f camera-backup*');
			shell_exec('sudo umount /media/storage');
			shell_exec('sudo ./camera-backup.sh > /dev/null 2>&1 & echo $!');
			echo "<script>";
			echo "UIkit.notification({message: '" . L::camerabackup_m . ", status: 'success''});";
			echo "</script>";
		}
		if (isset($_POST['internalbackup'])) {
			shell_exec('sudo pkill -f internal-backup*');
			shell_exec('sudo umount /media/storage');
			shell_exec('sudo ./internal-backup.sh > /dev/null 2>&1 & echo $!');
			echo "<script>";
			echo "UIkit.notification({message: '" . L::internalbackup_m . "', status: 'success'});";
			echo "</script>";
		}
		if (isset($_POST['shutdown'])) {
			echo "<script>";
			echo "UIkit.notification({message: '" . L::shutdown_m . "', status: 'danger'});";
			echo "</script>";
			shell_exec('sudo poweroff > /dev/null 2>&1 & echo $!');
		}
		?>
	</div>
</body>

</html>