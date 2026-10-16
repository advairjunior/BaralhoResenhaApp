using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>
/// Duelo de pedra, papel e tesoura: os dois sorteados escolhem em segredo no
/// celular, o app revela e quem perde leva. Empate: joguem de novo.
/// </summary>
public sealed class JokenpoTestes
{
    private static Carta Jokenpo(int? goles = null) => new("mp-pp", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve,
        "Pedra, papel e tesoura: {jogador} contra {jogador2}.", Duelo: true, Jokenpo: true, Goles: goles);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Duelista(int i) => Todos.Single(j => j.Id == Sala.Rodada!.Duelistas[i]);
        public Jogador Torcedor => Todos.First(j => !Sala.Rodada!.Duelistas.Contains(j.Id));
        public int Rodada => Sala.Rodada!.Numero;
    }

    private static Mesa Montar(Carta carta)
    {
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(3));
        var todos = new[] { "Ana", "Beto", "Caio" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, new ConfiguracaoDoJogo(NivelDaCarta.Leve, [ModoDeJogo.MaisProvavel], true,
            Ritmo: RitmoDaBebida.Raiz));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    [Fact]
    public void SoOsDoisDoDueloJogamEComPedraPapelOuTesoura()
    {
        var mesa = Montar(Jokenpo());

        Assert.Equal(2, mesa.Sala.Rodada!.Duelistas.Count);
        Assert.True(mesa.Sala.Visao(mesa.Torcedor.Token).Rodada!.Jokenpo);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Torcedor.Token, mesa.Rodada, Sala.Pedra));
        Assert.Equal("Só os dois do duelo jogam. Torce aí!", erro.Message);
        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Duelista(0).Token, mesa.Rodada, "lagarto"));
    }

    [Fact]
    public void PapelGanhaDePedraEQuemPerdeLevaOPonto()
    {
        var mesa = Montar(Jokenpo());
        var (ana, beto) = (mesa.Duelista(0), mesa.Duelista(1));

        mesa.Sala.Responder(ana.Token, mesa.Rodada, Sala.Pedra);
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        Assert.Null(mesa.Sala.Visao(beto.Token).Rodada!.Revelacao);
        mesa.Sala.Responder(beto.Token, mesa.Rodada, Sala.Papel);

        var revelacao = mesa.Sala.Rodada!.Revelacao!;
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal([beto.Id], revelacao.Escolhidos);
        Assert.Equal([ana.Id], revelacao.Perderam);
        Assert.Equal(Sala.Pedra, revelacao.Jogadas[ana.Id]);
        Assert.Equal(Sala.Papel, revelacao.Jogadas[beto.Id]);
        Assert.Equal(1, ana.Pontos);
        Assert.Equal(1, beto.Estatisticas.DuelosVencidos);
    }

    [Fact]
    public void EmpateZeraEOsDoisJogamDeNovo()
    {
        var mesa = Montar(Jokenpo());
        var (ana, beto) = (mesa.Duelista(0), mesa.Duelista(1));

        mesa.Sala.Responder(ana.Token, mesa.Rodada, Sala.Tesoura);
        mesa.Sala.Responder(beto.Token, mesa.Rodada, Sala.Tesoura);

        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        Assert.Equal([Sala.Tesoura], mesa.Sala.Visao(ana.Token).Rodada!.Empates);
        Assert.Null(mesa.Sala.Visao(ana.Token).Rodada!.MinhaResposta);

        mesa.Sala.Responder(ana.Token, mesa.Rodada, Sala.Tesoura);
        mesa.Sala.Responder(beto.Token, mesa.Rodada, Sala.Papel);
        Assert.Equal([ana.Id], mesa.Sala.Rodada!.Revelacao!.Escolhidos);
    }

    [Fact]
    public void ValendoDoseQuemPerdeBebeDeVerdade()
    {
        var mesa = Montar(Jokenpo(goles: 2));
        var (ana, beto) = (mesa.Duelista(0), mesa.Duelista(1));

        mesa.Sala.Responder(ana.Token, mesa.Rodada, Sala.Tesoura);
        mesa.Sala.Responder(beto.Token, mesa.Rodada, Sala.Pedra);

        Assert.Equal(2, ana.Goles);
        Assert.Equal(0, beto.Goles);
    }

    [Fact]
    public void SoRevelaQuandoOsDoisJogaram()
    {
        var mesa = Montar(Jokenpo());
        mesa.Sala.Responder(mesa.Duelista(0).Token, mesa.Rodada, Sala.Pedra);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Revelar(mesa.Todos[0].Token, mesa.Rodada));
        Assert.Equal("Os dois do duelo precisam jogar.", erro.Message);
    }
}
