namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>Um time da mímica: quem faz e quem adivinha (o mímico está junto).</summary>
public sealed record TimeDaMimica(Guid Mimico, IReadOnlyList<Guid> Jogadores);

/// <summary>
/// Imagem e Ação (e a Palavra proibida, que usa os mesmos times). Só quem faz a
/// mímica vê a palavra; a turma vê a dica.
/// Até 5 pessoas, uma faz para todos; de 6 a 8, dois times; 9 ou mais,
/// três. Nos times, todos os mímicos fazem a mesma palavra ao mesmo tempo
/// e ganha quem acertar primeiro.
/// </summary>
public sealed partial class Sala
{
    internal const int PessoasParaDoisTimes = 6;
    internal const int PessoasParaTresTimes = 9;

    /// <summary>
    /// Quem criou a sala marca o resultado: o número do time que acertou
    /// (com uma pessoa só fazendo, 0 = a turma acertou) ou nulo, ninguém acertou.
    /// </summary>
    public void ResultadoDaMimica(string token, int numeroDaRodada, int? timeVencedor)
    {
        lock (_trinco)
        {
            ExigirAnfitriao(token, "Quem marca o resultado é quem criou a sala.");
            if (!RodadaEmAndamento(numeroDaRodada) || Fase != FaseDaSala.Carta) return;
            var rodada = Rodada!;
            if (rodada.Carta.Modo is not (ModoDeJogo.ImagemEAcao or ModoDeJogo.PalavraProibida))
                throw new AcaoNaoPermitidaException("Só vale no Imagem e Ação e na Palavra proibida.");
            if (timeVencedor is { } indice && (indice < 0 || indice >= rodada.Times.Count))
                throw new AcaoNaoPermitidaException("Esse time não existe.");

            var presentes = _jogadores.Select(j => j.Id).ToHashSet();
            IEnumerable<Guid> perderam = timeVencedor switch
            {
                // Ninguém acertou: a culpa é de quem fez a mímica.
                null => rodada.Times.Select(t => t.Mimico),
                // Uma pessoa fazendo para todos: acertou, ninguém leva.
                _ when rodada.Times.Count == 1 => [],
                { } ganhou => rodada.Times.Where((_, i) => i != ganhou).SelectMany(t => t.Jogadores)
            };
            var vencedores = timeVencedor is { } v ? rodada.Times[v].Jogadores : [];
            // Palavra proibida não conta para o prêmio de artista da mímica.
            if (timeVencedor is { } acertou && rodada.Carta.Modo == ModoDeJogo.ImagemEAcao &&
                _jogadores.FirstOrDefault(j => j.Id == rodada.Times[acertou].Mimico) is { } artista)
                artista.Estatisticas.MimicasAcertadas++;

            var revelacao = new Revelacao([], [], [], perderam.Where(presentes.Contains).ToList(), null)
            {
                Escolhidos = vencedores.Where(presentes.Contains).ToList(),
                TimeVencedor = timeVencedor
            };
            // Revelação antes dos pontos: as cartas na manga olham a conta desta carta.
            rodada.Revelacao = revelacao;
            foreach (var jogador in _jogadores.Where(j => revelacao.Perderam.Contains(j.Id)))
                Pegar(jogador);
            // Time que acertou ganha carta; com uma pessoa só, quem fez a mímica.
            IReadOnlyList<Guid> premiados = rodada.Times.Count == 1 && timeVencedor is not null
                ? [rodada.Times[0].Mimico]
                : revelacao.Escolhidos;
            foreach (var jogador in _jogadores.Where(j => premiados.Contains(j.Id))) DarCarta(jogador);
            Fase = FaseDaSala.Revelada;
            Tocar();
        }
    }

    /// <summary>Mímico em rodízio: vai quem fez menos mímicas; os outros se dividem nos times.</summary>
    private List<TimeDaMimica> MontarTimes()
    {
        var quantidade = _jogadores.Count >= PessoasParaTresTimes ? 3
            : _jogadores.Count >= PessoasParaDoisTimes ? 2
            : 1;
        var mimicos = _jogadores
            .OrderBy(j => j.Estatisticas.Mimicas)
            .ThenBy(_ => _sorteio.Next())
            .Take(quantidade)
            .ToList();
        var times = mimicos.Select(m => new List<Guid> { m.Id }).ToList();
        var resto = _jogadores.Except(mimicos).OrderBy(_ => _sorteio.Next()).ToList();
        for (var i = 0; i < resto.Count; i++)
            times.OrderBy(t => t.Count).First().Add(resto[i].Id);
        foreach (var mimico in mimicos) mimico.Estatisticas.Mimicas++;
        return mimicos.Select((m, i) => new TimeDaMimica(m.Id, times[i])).ToList();
    }
}
