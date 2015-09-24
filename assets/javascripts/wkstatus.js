var warnMsg = ['The timesheet for this period is locked, you cannot log time.', 'The issue of this tracker type is not allowed.'];
var hasEntryError = false;
var hasTrackerError = false;

$(document).ready(function(){
	var txtEntryDate;
	var txtissuetracker;
	if(document.getElementById('divError') != null){
		if(document.getElementById('time_entry_issue_id')!=null){
			txtissuetracker = document.getElementById('time_entry_issue_id');		
		}
		if(document.getElementById('time_entry_spent_on')!=null){
			txtEntryDate = document.getElementById('time_entry_spent_on');	
		}
		else{
			//get current date
			var today = new Date();	
			today = today.getFullYear() + '-' + (today.getMonth()+1) + '-' + today.getDate();
			showEntryWarning(today);
		}		
	}	
	if(txtEntryDate!=null){		
		showEntryWarning(txtEntryDate.value);
		txtEntryDate.onchange=function(){showEntryWarning(this.value)};	
	}
	if( txtissuetracker != null)
	{
		showIssueWarning(txtissuetracker.value);
		//txtissuetracker.onblur=function(){showIssueWarning(this.value)};
		$("#time_entry_issue_id").change(function(event){
			var tb = this;
			event.preventDefault();						
			setTimeout(function() {
				var issId = document.getElementById('time_entry_issue_id').value;
				if(issId >= 0)
				{
					showIssueWarning(issId);
					return;					
				}
			}, 500);		
		});	
	}	
});

function showEntryWarning(entrydate){
	var $this = $(this);				
	var divID = document.getElementById('divError');	
	var statusUrl = document.getElementById('getstatus_url').value;		
	divID.style.display ='none';
	$.ajax({
		url: statusUrl,
		type: 'get',
		data: {startDate: entrydate},
		success: function(data){ showMessage(data,divID); },
		complete: function(){ $this.removeClass('ajax-loading'); }
	});		
}

function showMessage(data,divID){
	var errMsg = "";
	if(data!=null && ('s'== data || 'a'== data || 'l'== data)){		
		if (hasTrackerError) {
			errMsg = warnMsg[0] + "<br>" + warnMsg[1];
		}
		else {
			errMsg = warnMsg[0];
		}
		hasEntryError = true;
	}
	else {
		if (hasTrackerError) {
			errMsg = warnMsg[1];
		}
		hasEntryError = false;
	}

	if (errMsg != "") {	
		divID.innerHTML = errMsg;
		$('input[type="submit"]').prop('disabled', true);
		divID.style.display = 'block';
	}
	else {
		$('input[type="submit"]').prop('disabled', false);
		divID.style.display ='none';
	}
}

function showIssueWarning(issue_id){
	var $this = $(this);
	var divID = document.getElementById('divError');
	var trackerUrl = document.getElementById('getissuetracker_url').value;		
	divID.style.display ='none';
	$.ajax({
		data: 'issue_id=' + issue_id,
		url: trackerUrl,
		type: 'get',		
		success: function(data){ showIssueMessage(data, divID); },
		complete: function(){ $this.removeClass('ajax-loading'); }
	});	
}

function showIssueMessage(data,divID) {
	var errMsg = "";
	if (data == "false") {		
		if (hasEntryError) {
			errMsg = warnMsg[0] + "<br>" + warnMsg[1];
		}
		else {
			errMsg = warnMsg[1];
		}		
		hasTrackerError = true;		
	}
	else {
		if (hasEntryError) {
			errMsg = warnMsg[0];
		}
		hasTrackerError = false;		
	}	
	
	if (errMsg != "") {	
		divID.innerHTML = errMsg;
		$('input[type="submit"]').prop('disabled', true);
		divID.style.display = 'block';
	}
	else {
		$('input[type="submit"]').prop('disabled', false);
		divID.style.display = 'none';
	}
}
