String.prototype.htmlEscape = function(){
    var span = document.createElement('span');
    var txt =  document.createTextNode('');
    span.appendChild(txt);
    txt.data = this;
    return span.innerHTML;
};

$(function(){
    $('#title').click(function(){window.location = '/'});
});

var turn = '';
var toggle_lr = function(){
    if(turn == ''){
        turn = 'left'
    } 
    if(turn == 'left'){
        turn = 'right'
        return 'speech-right'
    }else {
        turn = 'left'
        return 'speech-left'
    }
}

var set_digits = function(id, val){
    $(id).val(Number(val)).trigger('change');
}
var clear_digits = function(){
    set_digits('#digit1', 0);
    set_digits('#digit2', 0);
    set_digits('#digit3', 0);
    set_digits('#digit4', 0);
    set_digits('#hit', 0);
    set_digits('#blow', 0);
}

var add_history = function(answer, hit, blow){
    var div = $('<div>').append(answer.htmlEscape() + ' Hit:' + hit.htmlEscape() + ' Blow:' + blow.htmlEscape());
    div.addClass(toggle_lr());
    $('div#results').prepend(div);
}

$(function(){
    $('#takein_btn').click(takein);
});

var takein = function(){
    var answer = $('#digit1').val() + $('#digit2').val() + $('#digit3').val() + $('#digit4').val();
    var hit = $('#hit').val();
    var blow = $('#blow').val();
    
    $.post('/post',
           { answer: answer,
             hit: hit,
             blow: blow
           },
           function(res){
               add_history(answer, hit, blow);
               set_matrix();
               clear_digits();
           });

}

$(function(){
    $('#expect_btn').click(expect);
});

var expect = function(){
    clear_digits();
    if(turn == ''){
        turn = 'right';
    }
    $.getJSON('/expect.json',
              function(res){
                  console.log(res.answer);
                  set_digits('#digit1', Number(res.answer[0]));
                  set_digits('#digit2', Number(res.answer[1]));
                  set_digits('#digit3', Number(res.answer[2]));
                  set_digits('#digit4', Number(res.answer[3]));
              });
};

var set_matrix = function(){
    $.getJSON('/candidate.json',
              function(res){
                  set_a_matrix('#matrix1', res.candidate[0]);
                  set_a_matrix('#matrix2', res.candidate[1]);
                  set_a_matrix('#matrix3', res.candidate[2]);
                  set_a_matrix('#matrix4', res.candidate[3]);
              });
}
var set_a_matrix = function(id, ary){
    console.log(ary);
    for(i = 0; i < 10; i++){
        $(id).find('.num'+i).removeClass('living');
        if($.inArray(i, ary) >= 0){
            console.log($(id).find('.nums'+i));
            $(id).find('.num'+i).addClass('living');
        }
    }
}

$(set_matrix());
