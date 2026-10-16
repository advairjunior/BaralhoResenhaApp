using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

public sealed class TribunalEElogioTestes
{
    private static ConfiguracaoDoJogo So(ModoDeJogo modo) => new(NivelDaCarta.Leve, [modo], ZonaSegura: true);

    private sealed record Mesa(Sala Sala, Jogador[] Todos)
    {
        public Jogador Reu => Todos.Single(j => j.Id == Sala.Rodada!.Alvo);
        public IEnumerable<Jogador> Jurados => Todos.Where(j => j.Id != Sala.Rodada!.Alvo);
    }

    private static Mesa Montar(Carta carta, ModoDeJogo modo)
    {
        var sala = new Sala("ABCD", new Baralho([carta]), new Random(4));
        var todos = new[] { "Ana", "Beto", "Caio", "Duda" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, So(modo));
        sala.Comecar(todos[0].Token);
        return new Mesa(sala, todos);
    }

    private static readonly Carta Zoeira =
        new("tr-1", ModoDeJogo.Tribunal, NivelDaCarta.Leve, "{jogador} tem cara de machão alfa?");
    private static readonly Carta ElogioNoTribunal =
        new("tr-2", ModoDeJogo.Tribunal, NivelDaCarta.Leve, "{jogador} recebe olhares na rua?", Elogio: true);

    [Fact]
    public void ReuEhOJogadorDaCartaENaoVota()
    {
        var mesa = Montar(Zoeira, ModoDeJogo.Tribunal);

        Assert.Equal($"{mesa.Reu.Nome} tem cara de machão alfa?", mesa.Sala.Rodada!.Texto);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Reu.Token, mesa.Sala.Rodada.Numero, Sala.RespostaSim));
        Assert.Equal("Essa é sobre você: espera o veredito da turma.", erro.Message);
        Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Jurados.First().Token, mesa.Sala.Rodada.Numero, "talvez"));
    }

    [Fact]
    public void QuandoOsJuradosVotamRevelaEMaioriaSimCondenaOReu()
    {
        var mesa = Montar(Zoeira, ModoDeJogo.Tribunal);
        var reu = mesa.Reu;
        var jurados = mesa.Jurados.ToList();
        var rodada = mesa.Sala.Rodada!.Numero;

        mesa.Sala.Responder(jurados[0].Token, rodada, Sala.RespostaSim);
        mesa.Sala.Responder(jurados[1].Token, rodada, Sala.RespostaSim);
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        mesa.Sala.Responder(jurados[2].Token, rodada, Sala.RespostaNao);

        var revelacao = mesa.Sala.Rodada.Revelacao!;
        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal(2, revelacao.JaFizeram.Count);
        Assert.Single(revelacao.NuncaFizeram);
        Assert.Equal([reu.Id], revelacao.Perderam);
        Assert.Equal([reu.Id], revelacao.Escolhidos);
        Assert.Equal(1, reu.Pontos);
    }

    [Fact]
    public void MaioriaNaoAbsolveEEmpateCondena()
    {
        var mesa = Montar(Zoeira, ModoDeJogo.Tribunal);
        var jurados = mesa.Jurados.ToList();
        var rodada = mesa.Sala.Rodada!.Numero;
        mesa.Sala.Responder(jurados[0].Token, rodada, Sala.RespostaNao);
        mesa.Sala.Responder(jurados[1].Token, rodada, Sala.RespostaNao);
        mesa.Sala.Responder(jurados[2].Token, rodada, Sala.RespostaSim);
        Assert.Empty(mesa.Sala.Rodada.Revelacao!.Perderam);

        mesa.Sala.Proxima(mesa.Todos[0].Token, rodada);
        var segunda = mesa.Sala.Rodada!.Numero;
        var reu = mesa.Reu;
        var outros = mesa.Jurados.ToList();
        mesa.Sala.Responder(outros[0].Token, segunda, Sala.RespostaSim);
        mesa.Sala.Responder(outros[1].Token, segunda, Sala.RespostaNao);
        mesa.Sala.Revelar(mesa.Todos[0].Token, segunda);

        Assert.Equal([reu.Id], mesa.Sala.Rodada.Revelacao!.Perderam);
    }

    [Fact]
    public void NoElogioDoTribunalQuemGanhaNaoBebeEContaParaOXodo()
    {
        var mesa = Montar(ElogioNoTribunal, ModoDeJogo.Tribunal);
        var reu = mesa.Reu;
        var rodada = mesa.Sala.Rodada!.Numero;
        foreach (var jurado in mesa.Jurados) mesa.Sala.Responder(jurado.Token, rodada, Sala.RespostaSim);

        var revelacao = mesa.Sala.Rodada.Revelacao!;
        Assert.True(revelacao.Elogio);
        Assert.Empty(revelacao.Perderam);
        Assert.Equal([reu.Id], revelacao.Escolhidos);
        Assert.Equal(0, reu.Pontos);
        Assert.Equal(3, reu.Estatisticas.Elogios);
        Assert.Equal("Xodó da turma", PremiosDaNoite.Calcular(mesa.Todos, [])[0].Titulo);
    }

    [Fact]
    public void ElogioNoQuemEhMaisProvavelEhSempreVotadoENinguemBebe()
    {
        var sala = new Sala("ABCD", new Baralho([
            new Carta("mp-1", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, "Quem tem o sorriso mais bonito?", Elogio: true),
        ]), new Random(1)) { ChanceDeVotacao = 0 };
        var todos = new[] { "Ana", "Beto", "Caio" }.Select(n => sala.Entrar(n, false)).ToArray();
        sala.Configurar(todos[0].Token, So(ModoDeJogo.MaisProvavel));
        sala.Comecar(todos[0].Token);

        Assert.True(sala.Rodada!.Votacao);
        foreach (var jogador in todos) sala.Responder(jogador.Token, sala.Rodada.Numero, todos[1].Id.ToString());

        var revelacao = sala.Rodada.Revelacao!;
        Assert.True(revelacao.Elogio);
        Assert.Empty(revelacao.Perderam);
        Assert.Equal([todos[1].Id], revelacao.Escolhidos);
        Assert.Equal(0, todos[1].Pontos);
        Assert.Equal(3, todos[1].Estatisticas.Elogios);
        Assert.Equal(0, todos[1].Estatisticas.VotosRecebidos);
    }

    [Fact]
    public void ReuEEscolhidoPodemTirarSelfieProMural()
    {
        var mesa = Montar(ElogioNoTribunal, ModoDeJogo.Tribunal);
        var reu = mesa.Reu;
        var rodada = mesa.Sala.Rodada!.Numero;
        foreach (var jurado in mesa.Jurados) mesa.Sala.Responder(jurado.Token, rodada, Sala.RespostaSim);

        mesa.Sala.RegistrarMomento(reu.Token, rodada, [0xFF, 0xD8, 0xFF]);

        Assert.Single(mesa.Sala.Visao(reu.Token).Momentos);
    }
}
