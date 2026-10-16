namespace BaralhoResenhaApp.Api.Dominio;

/// <summary>Cartas na manga, estilo Uno: cada um guarda e usa na hora certa.</summary>
public enum CartaNaManga
{
    /// <summary>Cancela o que a carta da mesa fez com você.</summary>
    Escudo,

    /// <summary>Sua conta inteira vai para quem você escolher.</summary>
    PassaABola,

    /// <summary>No duelo, a conta volta para quem te venceu.</summary>
    Devolve,

    /// <summary>Sua conta vira dose com +1 gole na pessoa escolhida, que pode passar adiante.</summary>
    BatataQuente,

    /// <summary>A conta de outra pessoa nesta carta dobra.</summary>
    Dobra
}

/// <param name="Goles">Batata quente: com quantos goles a batata chegou.</param>
public sealed record UsoDeCarta(Guid Quem, CartaNaManga Carta, Guid? Alvo, int? Goles = null);

public sealed partial class Sala
{
    internal const int MaximoNaMao = 3;

    /// <summary>A cada tantas cartas, quem está há mais tempo sem ganhar recebe uma.</summary>
    internal const int CartasParaPresente = 10;

    /// <summary>Escudo e Passa a bola saem mais; Devolve, que só vale no duelo, menos.</summary>
    private static readonly (CartaNaManga Carta, int Peso)[] PesosDasCartas =
    [
        (CartaNaManga.Escudo, 3), (CartaNaManga.PassaABola, 3), (CartaNaManga.BatataQuente, 2),
        (CartaNaManga.Dobra, 2), (CartaNaManga.Devolve, 1),
    ];

    public void UsarCarta(string token, int numeroDaRodada, CartaNaManga carta, Guid? alvoId)
    {
        lock (_trinco)
        {
            var jogador = Reconhecer(token);
            if (!RodadaEmAndamento(numeroDaRodada) || Fase is FaseDaSala.Lobby or FaseDaSala.Fim) return;
            if (!Configuracao.CartasNaManga)
                throw new AcaoNaoPermitidaException("As cartas na manga estão desligadas nesta noite.");
            if (!jogador.Mao.Contains(carta)) throw new AcaoNaoPermitidaException("Você não tem essa carta.");
            var rodada = Rodada!;
            if (rodada.Usos.Any(uso => uso.Quem == jogador.Id))
                throw new AcaoNaoPermitidaException("Uma carta na manga por carta da mesa.");
            var alvo = alvoId is { } id
                ? _jogadores.FirstOrDefault(j => j.Id == id) ?? throw new AcaoNaoPermitidaException("Essa pessoa não está na sala.")
                : null;

            int? golesDaBatata = null;
            switch (carta)
            {
                case CartaNaManga.Escudo:
                    ExigirConta(jogador);
                    Zerar(jogador);
                    break;
                case CartaNaManga.PassaABola:
                    ExigirConta(jogador);
                    alvo = ExigirOutraPessoa(jogador, alvo);
                    var (pontos, goles) = Zerar(jogador);
                    Aplicar(alvo, pontos, goles);
                    break;
                case CartaNaManga.BatataQuente:
                    ExigirConta(jogador);
                    alvo = ExigirOutraPessoa(jogador, alvo);
                    var (pontosDaBatata, golesAntes) = Zerar(jogador);
                    golesDaBatata = pontosDaBatata + golesAntes + 1;
                    Dose(alvo, golesDaBatata.Value);
                    break;
                case CartaNaManga.Dobra:
                    alvo = ExigirOutraPessoa(jogador, alvo);
                    var deles = Conta(alvo);
                    if (deles.Vazia)
                        throw new AcaoNaoPermitidaException("A carta não pegou essa pessoa: não tem o que dobrar.");
                    Aplicar(alvo, deles.Pontos, deles.Goles);
                    break;
                case CartaNaManga.Devolve:
                    ExigirConta(jogador);
                    alvo = rodada.Duelistas.Contains(jogador.Id) && rodada.Revelacao?.Escolhidos is [var vencedor] &&
                           vencedor != jogador.Id
                        ? _jogadores.FirstOrDefault(j => j.Id == vencedor)
                        : null;
                    if (alvo is null)
                        throw new AcaoNaoPermitidaException("Devolve só vale no duelo: o ponto volta para quem te venceu.");
                    var (devolvidos, golesDevolvidos) = Zerar(jogador);
                    Aplicar(alvo, devolvidos, golesDevolvidos);
                    break;
            }

            jogador.Mao.Remove(carta);
            jogador.Estatisticas.CartasUsadas++;
            rodada.Usos.Add(new UsoDeCarta(jogador.Id, carta, alvo?.Id, golesDaBatata));
            Tocar();
        }
    }

    private void ExigirConta(Jogador jogador)
    {
        if (Conta(jogador).Vazia)
            throw new AcaoNaoPermitidaException("A carta não te pegou: guarde a sua para depois.");
    }

    private static Jogador ExigirOutraPessoa(Jogador jogador, Jogador? alvo)
    {
        if (alvo is null) throw new AcaoNaoPermitidaException("Escolha em quem jogar a carta.");
        if (alvo.Id == jogador.Id) throw new AcaoNaoPermitidaException("Escolha outra pessoa.");
        return alvo;
    }

    /// <summary>Tira tudo o que a carta da mesa fez com a pessoa; devolve o que tirou.</summary>
    private (int Pontos, int Goles) Zerar(Jogador jogador)
    {
        var conta = Conta(jogador);
        var (pontos, goles) = (conta.Pontos, conta.Goles);
        for (var i = 0; i < pontos; i++) Despegar(jogador);
        TirarDose(jogador, goles);
        return (pontos, goles);
    }

    private void Aplicar(Jogador jogador, int pontos, int goles)
    {
        for (var i = 0; i < pontos; i++) Pegar(jogador);
        if (goles > 0) Dose(jogador, goles);
    }

    /// <summary>Uma carta nova na mão, se couber; a turma vê que a pessoa ganhou (não qual).</summary>
    private void DarCarta(Jogador jogador)
    {
        if (!Configuracao.CartasNaManga || jogador.Mao.Count >= MaximoNaMao) return;
        var ponto = _sorteio.Next(PesosDasCartas.Sum(p => p.Peso));
        var carta = PesosDasCartas.First(p => (ponto -= p.Peso) < 0).Carta;
        jogador.Mao.Add(carta);
        jogador.UltimaCartaEm = Rodada?.Numero ?? 0;
        Rodada?.Ganharam.Add(jogador.Id);
    }

    /// <summary>A cada <see cref="CartasParaPresente"/> cartas, quem está há mais tempo sem ganhar recebe uma.</summary>
    private void PresenteDaRodada()
    {
        if (!Configuracao.CartasNaManga || Rodada!.Numero % CartasParaPresente != 0) return;
        var quem = _jogadores
            .Where(j => j.Mao.Count < MaximoNaMao)
            .OrderBy(j => j.UltimaCartaEm)
            .ThenBy(_ => _sorteio.Next())
            .FirstOrDefault();
        if (quem is not null) DarCarta(quem);
    }
}
