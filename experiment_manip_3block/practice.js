var stimuli = [
  { stimulus: 'img/practice/S1.jpg', data:{state: 1, test_part:'practice', correct_response:83}},
  { stimulus: 'img/practice/S2.jpg', data:{state: 2, test_part:'practice', correct_response:68}},
  { stimulus: 'img/practice/S3.jpg', data:{state: 3, test_part:'practice', correct_response:72}},
  { stimulus: 'img/practice/S4.jpg', data:{state: 4, test_part:'practice', correct_response:74}}];


var trial = {
	type: 'image-keyboard-response',
	stimulus: jsPsych.timelineVariable('stimulus'),
	stimulus_height: 360, stimulus_width: 540,
	choices: ['s','d','h','j'],
	trial_duration: 2500,
	data: jsPsych.timelineVariable('data'),
	on_finish: function(data){
		data.correct = data.key_press == data.correct_response;
		trial_node_id = jsPsych.currentTimelineNodeID();
	}
};

var fixation = {
	type: 'html-keyboard-response',
    stimulus: '',
    choices: jsPsych.NO_KEYS,
    trial_duration: 0 // ms
 };

var feedback = {
	type: 'html-keyboard-response',
	stimulus: function(){
		var prev_trial = jsPsych.data.getDataByTimelineNode(trial_node_id);
		var feedback_img = prev_trial.select('stimulus').values[0];
		var feedback = prev_trial.select('key_press').values[0];
		if (prev_trial.select('correct').values[0]){
			return  '<img src="' + feedback_img + '" width="540" height = "360" style="border:16px solid orange">';
  		}else{
  			return '<img src="' + feedback_img + '" width="540" height = "360">';
  		}
  	},
	choices: jsPsych.NO_KEYS,
	trial_duration: 300
};


var finished = {
  	type: 'instructions',
  	pages: [
  	'<p class="center-content">You have completed the practice round!</p>'+ 
  	'<p class="center-content">Click "Next" to continue to the first experimental block.</p>'
  	],
  	show_clickable_nav: true,
  	button_label_next: 'Next'
  };


var block = {
	timeline: [trial, feedback, fixation],
	timeline_variables: stimuli,
	randomize_order: true,
	repetitions: 6
};

function create_practice_block() {
	return block; 
  console.log("Creating the practice block!");
};

function finish_practice_block() {
  console.log("Finishing the practice trials.");
  return finished;
}