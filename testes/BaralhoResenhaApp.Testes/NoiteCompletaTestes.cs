using BaralhoResenhaApp.Api.Dominio;

namespace BaralhoResenhaApp.Testes;

/// <summary>Casais em Jogo, mural da noite e Prêmios da Noite.</summary>
public sealed class NoiteCompletaTestes
{
    private static readonly byte[] Jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10];

    private static ConfiguracaoDoJogo So(ModoDeJogo modo) => new(NivelDaCarta.Leve, [modo], ZonaSegura: true);

    private static Baralho BaralhoDeTeste() => new([
        new Carta("en-1", ModoDeJogo.EuNunca, NivelDaCarta.Leve, "Eu nunca 1"),
        new Carta("mp-1", ModoDeJogo.MaisProvavel, NivelDaCarta.Leve, "Quem 1"),
        new Carta("bs-1", ModoDeJogo.BebaSe, NivelDaCarta.Leve, "Beba se 1"),
        new Carta("cs-1", ModoDeJogo.CasaisEmJogo, NivelDaCarta.Leve, "Qual a comida que {par} mais odeia?"),
    ]);

    private sealed record Mesa(Sala Sala, Jogador Ana, Jogador Beto, Jogador Caio, Jogador Duda);

    /// <summary>Ana e Beto são casados; Caio e Duda também, se <paramref name="doisCasais"/>.</summary>
    private static Mesa MontarMesa(ModoDeJogo modo, bool doisCasais = false)
    {
        var sala = new Sala("ABCD", BaralhoDeTeste(), new Random(5));
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        var caio = sala.Entrar("Caio", false);
        var duda = sala.Entrar("Duda", true);
        sala.DefinirPar(ana.Token, beto.Id);
        if (doisCasais) sala.DefinirPar(caio.Token, duda.Id);
        sala.Configurar(ana.Token, So(modo));
        sala.Comecar(ana.Token);
        return new Mesa(sala, ana, beto, caio, duda);
    }

    private static Jogador Pelo(Mesa mesa, Guid? id) =>
        new[] { mesa.Ana, mesa.Beto, mesa.Caio, mesa.Duda }.Single(j => j.Id == id);

    [Fact]
    public void ParFicaMarcadoNosDoisEDesfazAoTrocarOuSair()
    {
        var sala = new Sala("ABCD", BaralhoDeTeste());
        var ana = sala.Entrar("Ana", false);
        var beto = sala.Entrar("Beto", false);
        var caio = sala.Entrar("Caio", false);

        sala.DefinirPar(ana.Token, beto.Id);
        Assert.Equal(beto.Id, ana.ParId);
        Assert.Equal(ana.Id, beto.ParId);

        sala.DefinirPar(caio.Token, ana.Id);
        Assert.Null(beto.ParId);
        Assert.Equal(caio.Id, ana.ParId);

        sala.Sair(caio.Token);
        Assert.Null(ana.ParId);
        Assert.Throws<AcaoNaoPermitidaException>(() => sala.DefinirPar(ana.Token, ana.Id));
    }

    [Fact]
    public void SemCasalNaSalaCasaisEmJogoNaoSai()
    {
        var sala = new Sala("ABCD", BaralhoDeTeste());
        var ana = sala.Entrar("Ana", false);
        sala.Entrar("Beto", false);
        sala.Configurar(ana.Token, So(ModoDeJogo.CasaisEmJogo));

        var erro = Assert.Throws<AcaoNaoPermitidaException>(() => sala.Comecar(ana.Token));
        Assert.Equal("Nenhuma carta combina com essa configuração.", erro.Message);
    }

    [Fact]
    public void CartaDoCasalPerguntaSobreOAlvoESoOCasalResponde()
    {
        var mesa = MontarMesa(ModoDeJogo.CasaisEmJogo);
        var rodada = mesa.Sala.Rodada!;
        var alvo = Pelo(mesa, rodada.Alvo);
        var palpiteiro = Pelo(mesa, rodada.Palpiteiro);

        Assert.Equal(new[] { mesa.Ana.Id, mesa.Beto.Id }.Order(), new[] { alvo.Id, palpiteiro.Id }.Order());
        Assert.Equal($"Qual a comida que {alvo.Nome} mais odeia?", rodada.Texto);
        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.Responder(mesa.Caio.Token, rodada.Numero, "jiló"));
        Assert.Equal("Essa carta é do casal: só os dois respondem.", erro.Message);
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Responder(alvo.Token, rodada.Numero, "   "));
    }

    [Fact]
    public void QuandoOCasalRespondeRevelaEAlvoJulga()
    {
        var mesa = MontarMesa(ModoDeJogo.CasaisEmJogo);
        var rodada = mesa.Sala.Rodada!;
        var alvo = Pelo(mesa, rodada.Alvo);
        var palpiteiro = Pelo(mesa, rodada.Palpiteiro);

        mesa.Sala.Responder(alvo.Token, rodada.Numero, " Jiló ");
        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        mesa.Sala.Responder(palpiteiro.Token, rodada.Numero, "Quiabo");

        Assert.Equal(FaseDaSala.Revelada, mesa.Sala.Fase);
        Assert.Equal("Jiló", rodada.Revelacao!.RespostaDoAlvo);
        Assert.Equal("Quiabo", rodada.Revelacao.PalpiteDoPar);
        Assert.Empty(rodada.Revelacao.Perderam);

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Julgar(palpiteiro.Token, rodada.Numero, true));
        mesa.Sala.Julgar(alvo.Token, rodada.Numero, acertou: false);
        mesa.Sala.Julgar(alvo.Token, rodada.Numero, acertou: true);

        Assert.False(rodada.Acertou);
        Assert.Equal([palpiteiro.Id], rodada.Revelacao!.Perderam);
        Assert.Equal(1, palpiteiro.Pontos);
        Assert.Equal(1, palpiteiro.Estatisticas.Erros);
    }

    [Fact]
    public void CasaisSeRevezam()
    {
        var mesa = MontarMesa(ModoDeJogo.CasaisEmJogo, doisCasais: true);
        var palpiteiros = new List<Guid>();
        for (var i = 0; i < 4; i++)
        {
            palpiteiros.Add(mesa.Sala.Rodada!.Palpiteiro!.Value);
            mesa.Sala.Proxima(mesa.Ana.Token, mesa.Sala.Rodada.Numero);
        }

        Assert.Equal(4, palpiteiros.Distinct().Count());
    }

    [Fact]
    public void SoQuemFoiPegoEntraNoMuralENaHoraDaRevelacao()
    {
        var mesa = MontarMesa(ModoDeJogo.EuNunca);
        var rodada = mesa.Sala.Rodada!.Numero;
        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.RegistrarMomento(mesa.Ana.Token, rodada, Jpeg));

        mesa.Sala.Responder(mesa.Ana.Token, rodada, Sala.RespostaJa);
        mesa.Sala.Responder(mesa.Beto.Token, rodada, Sala.RespostaNunca);
        mesa.Sala.Responder(mesa.Caio.Token, rodada, Sala.RespostaNunca);
        mesa.Sala.Responder(mesa.Duda.Token, rodada, Sala.RespostaNunca);

        var erro = Assert.Throws<AcaoNaoPermitidaException>(
            () => mesa.Sala.RegistrarMomento(mesa.Beto.Token, rodada, Jpeg));
        Assert.Equal("Só quem foi pego nesta carta entra no mural.", erro.Message);

        mesa.Sala.RegistrarMomento(mesa.Ana.Token, rodada, Jpeg);
        mesa.Sala.RegistrarMomento(mesa.Ana.Token, rodada, Jpeg);

        var momento = Assert.Single(mesa.Sala.Visao(mesa.Beto.Token).Momentos);
        Assert.Equal(mesa.Ana.Id, momento.JogadorId);
        Assert.Equal("Eu nunca 1", momento.Texto);
        Assert.NotNull(mesa.Sala.Foto(momento.Id));
    }

    [Fact]
    public void SoOAnfitriaoEncerraENoFimSaemOsPremios()
    {
        var mesa = MontarMesa(ModoDeJogo.EuNunca);
        var rodada = mesa.Sala.Rodada!.Numero;
        mesa.Sala.Responder(mesa.Ana.Token, rodada, Sala.RespostaJa);
        mesa.Sala.Responder(mesa.Beto.Token, rodada, Sala.RespostaNunca);
        mesa.Sala.Revelar(mesa.Ana.Token, rodada);

        Assert.Throws<AcaoNaoPermitidaException>(() => mesa.Sala.Encerrar(mesa.Beto.Token));
        mesa.Sala.Encerrar(mesa.Ana.Token);

        var visao = mesa.Sala.Visao(mesa.Caio.Token);
        Assert.Equal(FaseDaSala.Fim, visao.Fase);
        Assert.Null(visao.Rodada);
        var rei = visao.Premios!.Single(p => p.Titulo == "Rei(nha) da noite");
        Assert.Equal([mesa.Ana.Id], rei.Jogadores);
        Assert.Equal("1 ponto", rei.Descricao);
        Assert.Equal(new ResumoDaNoite(1, 0, 0, 0), visao.Resumo);

        mesa.Sala.Proxima(mesa.Ana.Token, rodada);
        Assert.Equal(FaseDaSala.Fim, mesa.Sala.Fase);
    }

    [Fact]
    public void SoMaisUmaVoltaAoJogoComPlacarMantido()
    {
        var mesa = MontarMesa(ModoDeJogo.BebaSe);
        mesa.Sala.AlternarBebi(mesa.Caio.Token, mesa.Sala.Rodada!.Numero);
        mesa.Sala.Encerrar(mesa.Ana.Token);

        mesa.Sala.Retomar(mesa.Ana.Token);

        Assert.Equal(FaseDaSala.Carta, mesa.Sala.Fase);
        Assert.Equal(2, mesa.Sala.Rodada!.Numero);
        Assert.Equal(1, mesa.Caio.Pontos);
        Assert.Null(mesa.Sala.Visao(mesa.Ana.Token).Premios);
    }

    [Fact]
    public void PremiosSoAparecemComAlguemPontuandoEEmpateLevaJunto()
    {
        var ana = new Jogador { Id = Guid.NewGuid(), Token = "a", Nome = "Ana", Pontos = 3 };
        var beto = new Jogador { Id = Guid.NewGuid(), Token = "b", Nome = "Beto", Pontos = 3 };
        var duda = new Jogador { Id = Guid.NewGuid(), Token = "d", Nome = "Duda", SemAlcool = true, Pontos = 1 };
        ana.Estatisticas.Historias = 2;
        ana.Estatisticas.Acertos = 2;
        beto.Estatisticas.Acertos = 1;

        var premios = PremiosDaNoite.Calcular([ana, beto, duda], [(ana, beto)]);

        Assert.Equal(["Rei(nha) da noite", "Contador(a) de histórias", "Casal em sintonia"],
            premios.Select(p => p.Titulo));
        Assert.Equal([ana.Id, beto.Id], premios[0].Jogadores);
        Assert.Equal("Acertaram 3 palpites um sobre o outro", premios[2].Descricao);
    }

    [Fact]
    public void QuemJogaSemAlcoolGanhaEmPontos()
    {
        var duda = new Jogador { Id = Guid.NewGuid(), Token = "d", Nome = "Duda", SemAlcool = true, Pontos = 4 };
        var ana = new Jogador { Id = Guid.NewGuid(), Token = "a", Nome = "Ana", Pontos = 2 };

        var rei = PremiosDaNoite.Calcular([ana, duda], [])[0];

        Assert.Equal("4 pontos", rei.Descricao);
    }

    [Fact]
    public void ReiDaNoiteMostraPontosEGolesDeVerdade()
    {
        var ana = new Jogador { Id = Guid.NewGuid(), Token = "a", Nome = "Ana", Pontos = 7, Goles = 2 };

        Assert.Equal("7 pontos · 2 goles", PremiosDaNoite.Calcular([ana], [])[0].Descricao);
    }
}
