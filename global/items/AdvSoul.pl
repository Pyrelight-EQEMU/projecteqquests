sub EVENT_SCALE_CALC {
    my $attunements = plugin::get_total_attunements($client) || 0;
    my $classCount = my $count = keys %{ { plugin::GetUnlockedClasses($client) } } || 1;

    my $scale = ($attunements/5) + ($classCount - 1);

    $questitem->SetScale($scale);
}