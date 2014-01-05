var select_digit = function(select, obj){
    var set_selectbox = function(){
        var value = $(this).find('option:selected').html();
        $(this).siblings(obj).find('span').html(value);
    }
    $(select).each(set_selectbox).change(set_selectbox);
}
 
$(function(){
    select_digit('.select-digit select', '.selected');
});
